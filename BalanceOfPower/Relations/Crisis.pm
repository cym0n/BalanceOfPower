package BalanceOfPower::Relations::Crisis;

use strict;
use v5.10;

use Moo;

has factor => (
    is => 'rw',
    default => 1
);

with 'BalanceOfPower::Relations::Role::Relation';

sub print 
{
    my $self = shift;
    return $self->node1 . " <-> " . $self->node2 . " (" . $self->factor . ")";
}

1;
