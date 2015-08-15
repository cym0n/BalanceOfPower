use BalanceOfPower::World;
use BalanceOfPower::Utils qw(prev_year next_year random random10 get_year_turns);
use BalanceOfPower::World;

use strict;

#Initial status
my @nation_names = ("Italy", "France", "United Kingdom", "Russia", 
                    "Germany", "Spain", "Greece", "Switzerland", 
                    "Finland", "Sweden", "Norway", "Netherlands", 
                    "Belgium", "Portugal", "Denmark", "Austria",
                    "Czech Republic", "Slovakia", "Slovenia", "Hungary",
                    "Poland", "Turkey", "Bulgaria", "Albania" ); 
my $first_year = 1970;
my $last_year = 1995;

#Init
my $world = BalanceOfPower::World->new();
$world->init_random(@nation_names);
$world->init_year("0/0");
my $italy = $world->get_nation("Italy");
my $denmark = $world->get_nation("Denmark");

#TODO: Rewrite
#$world->under_influence($italy, $world->get_nation("France"));
#$world->under_influence($italy, $world->get_nation("Spain"));
#$world->under_influence($denmark, $world->get_nation("Germany"));
#$world->under_influence($denmark, $world->get_nation("Greece"));
$world->create_war($italy, $denmark);




