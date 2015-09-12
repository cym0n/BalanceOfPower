package BalanceOfPower::Relations::MilitarySupport;

use strict;
use v5.10;

use Moo;

with 'BalanceOfPower::Relations::Role::Relation';

has army => (
    is => 'rw',
    default => 0
);


sub bidirectional
{
    return 0;
}

sub print 
{
    my $self = shift;
    return $self->node1 . " --> " . $self->node2 . " [" . $self->army . "]";
}



1;
