#!/usr/bin/perl

use v5.10;
use strict;

use IO::Prompter;
use Term::ANSIColor;
use BalanceOfPower::Utils qw(get_year_turns compare_turns);
use BalanceOfPower::World;
use BalanceOfPower::Commands;

my $stubbed_player = 0;

unlink "bop.log";
unlink "bop-dice.log";

if($ARGV[0] == 'devel')
{
   $stubbed_player = 1;
}

my $first_year = 1970;

my $world = BalanceOfPower::World->new( first_year => $first_year );
$world->init_random();
my $commands = BalanceOfPower::Commands->new( world => $world );
my $auto_years = $commands->init_game($stubbed_player);
$world->autoplay(1);
for($first_year..$first_year+$auto_years)
{
    my $y = $_;
    foreach my $t (get_year_turns($y))
    {
        $world->elaborate_turn($t);
    }
}
$world->autoplay(0);
say "=======\n\n\n";
$commands->init();
$commands->welcome_player();
$commands->interact();




