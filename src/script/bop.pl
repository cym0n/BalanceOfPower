#!/usr/bin/perl

use v5.10;
use strict;

use IO::Prompter;
use Term::ANSIColor;
use BalanceOfPower::Utils qw(get_year_turns compare_turns);
use BalanceOfPower::World;


my $stubbed_player = 0;
my $logs = 0;

my $mode = shift @ARGV;
if($mode eq 'devel')
{
   say "DEVELOPEMENT MODE";
   $stubbed_player = 1;
   $logs = 1;
}
elsif($mode eq 'fastdev')
{
   say "DEVELOPEMENT MODE";
   $stubbed_player = 1;
   $logs = 0;
}
my $world;
my $commands;
my $first_year;
my $auto_years;


$first_year = 1970;
$world = BalanceOfPower::World->new( first_year => $first_year, log_active => $logs );
$world->dice_log($logs);
$world->init_random("nations-v2.txt", "borders-v2.txt");

$commands = $world->build_commands();
$auto_years = $commands->init_game($stubbed_player);

$world->autopilot($first_year, $first_year+$auto_years);

$commands->init();
$commands->welcome_player();
$commands->interact();




