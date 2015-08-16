package BalanceOfPower::Relations::War;

use strict;
use v5.10;

use Moo;

with 'BalanceOfPower::Relations::Role::Relation';

has attack_leader => (
    is => 'rw',
    default => ""
);


sub bidirectional
{
    return 0;
}



1;
