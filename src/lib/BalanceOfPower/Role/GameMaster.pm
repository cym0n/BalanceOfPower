package BalanceOfPower::Role::GameMaster;

use strict;
use v5.10;

use Moo::Role;

use BalanceOfPower::Player;
use BalanceOfPower::Targets::Fall;

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
    my $pl = BalanceOfPower::Player->new(name => $username, money => START_PLAYER_MONEY, log_name => $log_name, log_dir => $self->log_dir, current_year => $self->current_year, position => 'Italy');
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

sub player_targets
{
    my $self = shift;
    for(@{$self->players})
    {
        my $p = $_;
        if($p->no_targets)
        {
            my $obj = BalanceOfPower::Targets::Fall->select_random_target($self);
            if($obj)
            {
                my $target = BalanceOfPower::Targets::Fall->new(target_obj => $obj, 
                                                                government_id => $obj->government_id, 
                                                                countdown => TIME_FOR_TARGET);
                $p->add_target($target);
            }
        }
        else
        {
            $p->check_targets($self);
            $p->click_targets();
        }
    }
}
sub print_targets
{
    my $self = shift;
    my $player = shift;
    my $mode = shift || 'print';
    my $player_obj = $self->get_player($player);
    return BalanceOfPower::Printer::print($mode, $self, 'print_targets', 
                                   { player => $player,
                                     points => $player_obj->mission_points,
                                     targets => $player_obj->targets,
                                   } );
}

1;
