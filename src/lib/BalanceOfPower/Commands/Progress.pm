package BalanceOfPower::Commands::Progress;

use Moo;

use BalanceOfPower::Constants ":all";
use BalanceOfPower::Utils qw( prev_turn );

extends 'BalanceOfPower::Commands::NoArgs';

sub IA
{
    return "PROGRESS";
}

1;
