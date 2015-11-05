use v5.10;
use lib "lib";
use BalanceOfPower::World;
use BalanceOfPower::Commands;
use Test::More;

#Initialization of test scenario
my $first_year = 1970;


#Scenario: a neighbor has military support from an enemy nation
my $world = BalanceOfPower::World->new( first_year => $first_year );
$world->init_random("nations-test1.txt", "borders-test1.txt", 
                    { alliances => 0, trades => 0 });
$world->add_crisis('Italy', 'United Kingdom' );
$world->change_diplomacy('Italy', 'Germany', 100);
$world->change_diplomacy('Italy', 'France', 100);
$world->change_diplomacy('Italy', 'United Kingdom', -100);
$world->change_diplomacy('Germany', 'United Kingdom', 100);
$world->get_nation('United Kingdom')->army(20);
$world->start_military_support($world->get_nation('United Kingdom'), $world->get_nation('Germany'));
my $italy = $world->get_nation('Italy');
$italy->production(100);
$italy->prestige(20);
$world->forced_advisor("domestic");
is($italy->decision($world), 'Italy: TREATY NAG WITH Germany', "Italy will subscribe a non aggression treaty with Germany (dangerous neighbor)");

#Scenario: neutralize the supporter of the enemy
$world = BalanceOfPower::World->new( first_year => $first_year );
$world->init_random("nations-test1.txt", "borders-test1.txt", 
                    { alliances => 0, trades => 0 });
$world->add_crisis('Italy', 'United Kingdom' );
$world->change_diplomacy('Italy', 'Germany', 100);
$world->change_diplomacy('Italy', 'France', 100);
$world->change_diplomacy('Italy', 'United Kingdom', -100);
$world->change_diplomacy('Russia', 'United Kingdom', 100);
$world->change_diplomacy('Russia', 'Italy', 100);
$world->get_nation('Russia')->army(20);
$world->start_military_support($world->get_nation('Russia'), $world->get_nation('United Kingdom'));
$italy = $world->get_nation('Italy');
$italy->production(100);
$italy->prestige(20);
$world->forced_advisor("domestic");
is($italy->decision($world), 'Italy: TREATY NAG WITH Russia', "Italy will subscribe a non aggression treaty with Russia (enemy supporter)");
say $italy->decision($world);

#Scenario: neutralize the ally of the enemy
$world = BalanceOfPower::World->new( first_year => $first_year );
$world->init_random("nations-test1.txt", "borders-test1.txt", 
                    { alliances => 0, trades => 0 });
$world->add_crisis('Italy', 'United Kingdom' );
$world->change_diplomacy('Italy', 'Germany', 100);
$world->change_diplomacy('Italy', 'France', 100);
$world->change_diplomacy('Italy', 'United Kingdom', -100);
$world->change_diplomacy('Russia', 'United Kingdom', 100);
$world->change_diplomacy('Russia', 'Italy', 100);
$world->add_alliance('Russia', 'United Kingdom');
$italy = $world->get_nation('Italy');
$italy->production(100);
$italy->prestige(20);
$world->forced_advisor("domestic");
is($italy->decision($world), 'Italy: TREATY NAG WITH Russia', "Italy will subscribe a non aggression treaty with Russia (enemy ally)");
say $italy->decision($world);

#Scenario: generic neighbor
$world = BalanceOfPower::World->new( first_year => $first_year );
$world->init_random("nations-test1.txt", "borders-test1.txt", 
                    { alliances => 0, trades => 0 });
$world->add_crisis('Italy', 'United Kingdom' );
$world->change_diplomacy('Italy', 'Germany', -100);
$world->change_diplomacy('Italy', 'France', 100);
$world->change_diplomacy('Italy', 'United Kingdom', -100);
$world->change_diplomacy('Russia', 'United Kingdom', 100);
$world->change_diplomacy('Russia', 'Italy', 100);
$italy = $world->get_nation('Italy');
$italy->production(100);
$italy->prestige(20);
$world->forced_advisor("domestic");
is($italy->decision($world), 'Italy: TREATY NAG WITH France', "Italy will subscribe a non aggression treaty with France (generic friendly neighbor)");
say $italy->decision($world);







done_testing();

