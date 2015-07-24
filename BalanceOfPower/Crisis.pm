package BalanceOfPower::Crisis;

use strict;
use v5.10;

use Moo;

has factor => (
    is => 'rw',
    default => 1
);

with 'BalanceOfPower::Role::Relation';

1;
