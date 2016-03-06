package BalanceOfPower::Role::GameMaster;

use strict;
use v5.10;

use Moo::Role;

use BalanceOfPower::Player;

use BalanceOfPower::Constants ':all';

has players => (
    is => 'rw',
    default => sub { [] }
);

sub get_player
{
    my $self = shift;
    my $name = shift;
    my @good = grep { $_->name eq $name} @{$self->players};
    if(@good)
    {
        return $good[0];
    }
    else
    {
        return undef;
    }
}
sub create_player
{
    my $self = shift;
    my $username = shift;
    my $already = $self->get_player($username);
    return 0 if($already);
    my $log_name = $username . ".log";
    $log_name =~ s/ /_/g;
    my $pl = BalanceOfPower::Player->new(name => $username, money => START_PLAYER_MONEY, log_name => $log_name, log_dir => $self->log_dir, current_year => $self->current_year);
    $pl->delete_log();
    $pl->register_event("ENTERING THE GAME");
    $self->register_event("$username IS ENTERING THE GAME");
    $self->add_player($pl);
    return 1;
}


sub add_player
{
    my $self = shift;
    my $player = shift;
    if($self->get_player($player->name))
    {
        return 0;
    }
    else
    {
        push @{$self->players}, $player;
        return 1;
    }
}
sub delete_player
{
    my $self = shift;
    my $player = shift;
    my @players = grep { $_->name ne $player} @{$self->players};
    $self->players(\@players);
}
sub player_current_year
{
    my $self = shift;
    for(@{$self->players})
    {
        $_->current_year($self->current_year);
    }
}

1;
