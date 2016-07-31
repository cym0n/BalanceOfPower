package BalanceOfPower::Player::Role::Cargo;

use strict;
use v5.10;
use Moo::Role;

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils;

has hold => (
    is => 'ro',
    default => sub { {} }
);

sub add_cargo
{
    my $self;
    my $type;
    my $q;

    my $present = $self->get_cargo($type);
    my $new = $present + $q;
    return -1 if($new < 0);
    $self->hold->{type} = $new;
    return 1;
}

sub get_cargo
{
    my $self = shift;
    my $type = shift;
    if(exists $self->hold->{$type})
    {
        return $self->hold->{$type};
    }
    else
    {
        return 0;
    }
}

sub cargo_free_space
{
    my $self = shift;
    my $occupied = 0;
    foreach my $t (%{$self->hold})
    {
        $occupied += $self->hold->{$t};
    }
    if($occupied > CARGO_TOTAL_SPACE)
    {
        say "Load exceed available space";
        return 0;
    }
    else
    {   
        return CARGO_TOTAL_SPACE - $occupied;
    }
}

