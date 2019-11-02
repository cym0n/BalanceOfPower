package BalanceOfPower::Relations::Border;

use strict;
use v5.10;

use Moo;

with 'BalanceOfPower::Relations::Role::Relation';

has '+rel_type' => (
    is => 'ro',
    default => 'border'
);


1;
