package BalanceOfPower::Player;

use strict;
use v5.10;

use Moo;

use BalanceOfPower::Constants ':all';

has name => (
    is => 'ro',
    default => 'Player'
);

1;
