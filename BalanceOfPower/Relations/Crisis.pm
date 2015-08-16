package BalanceOfPower::Relations::Crisis;

use strict;
use v5.10;

use Moo;

has factor => (
    is => 'rw',
    default => 1
);

with 'BalanceOfPower::Relations::Role::Relation';

1;
