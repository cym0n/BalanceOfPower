package BalanceOfPower::Relations::Treaty;

use strict;
use v5.10;

use Moo;

with 'BalanceOfPower::Relations::Role::Relation';

has type => (
    is => 'ro',
);

around 'print' => sub {
    my $orig = shift;
    my $self = shift;
    return $self->type . ": " .
           $self->$orig();
};

1;
