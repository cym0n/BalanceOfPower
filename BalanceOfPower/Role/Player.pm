package BalanceOfPower::Role::Player;

use strict;
use v5.10;

use Moo::Role;


has player => (
    is => 'rw',
    default => 'PLAYER1'
);
has player_nation => (
    is => 'rw',
    default => 'Italy'
);

1;
