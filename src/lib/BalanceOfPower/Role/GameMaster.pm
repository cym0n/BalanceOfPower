package BalanceOfPower::Role::GameMaster;

use strict;
use v5.10;

use Moo::Role;

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

1;
