package BalanceOfPower::War;

use strict;
use v5.10;

use Moo;

with 'BalanceOfPower::Role::Relation';

has attack_leader => (
    is => 'rw',
    default => ""
);


sub bidirectional
{
    return 0;
}



1;
