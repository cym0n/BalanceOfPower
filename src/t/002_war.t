use v5.10;
use lib "lib";
use BalanceOfPower::World;
use BalanceOfPower::Commands;
use Test::More;

#Initialization of test scenario
my $first_year = 1970;
my $world = BalanceOfPower::World->new( first_year => $first_year, silent => 1 );

$world->tricks( { "Export quote Italy" => [30],
                  "Export quote France" => [30],
                  "Export quote Russia" => [30],
                  "Export quote Germany" => [30],
                  "Starting production0 Italy" => [30],
                  "Starting production1 Italy" => [30],
                  "Starting production2 Italy" => [30],
                  "Starting production3 Italy" => [30],
                  "Starting production0 France" => [30],
                  "Starting production1 France" => [30],
                  "Starting production2 France" => [30],
                  "Starting production3 France" => [30],
                  "Starting production0 Russia" => [30],
                  "Starting production1 Russia" => [30],
                  "Starting production2 Russia" => [30],
                  "Starting production3 Russia" => [30],
                  "Starting production0 Germany" => [30],
                  "Starting production1 Germany" => [30],
                  "Starting production2 Germany" => [30],
                  "Starting production3 Germany" => [30],
                  "Delta production Italy" => [(0) x 20],
                  "Delta production France" => [(0) x 20],
                  "Delta production Russia" => [(0) x 20],
                  "Delta production Germany" => [(0) x 20],
                  "Crisis action choose" => [(5) x 20],
                  "War risiko: throw for attacker Italy" => [(60) x 20],
                  "War risiko: throw for defender France" => [(1) x 20],
                  "War risiko: throw for attacker Russia" => [(1) x 20],
                  "War risiko: throw for defender Germany" => [(60) x 20],
              });  
$world->init_random("nations-test2.txt", "borders-test2.txt", 
                    { alliances => 0, trades => 0 });
$world->forced_advisor("Noone");
$commands = $world->build_commands();
$commands->init_game(1);
my $result;

$world->add_crisis('Italy', 'France');
$world->get_nation("Italy")->army(6);
$world->get_nation("Italy")->internal_disorder(0);
$world->get_nation("Germany")->army(6);
$world->get_nation("Germany")->internal_disorder(0);
$world->get_nation("Russia")->army(6);
$world->get_nation("Russia")->internal_disorder(0);
$world->get_nation("France")->army(6);
$world->get_nation("France")->internal_disorder(0);
$world->get_nation("France")->progress(0.1);
$world->get_nation("Italy")->progress(0);
$world->occupy("Germany", [ "Italy" ], "Italy", 1);
$world->occupy("Russia", [ "France" ], "France", 1);
$world->situation_clock();
$world->order("DECLARE WAR TO France");
$world->elaborate_turn("1970/1");
ok($world->war_exists("Italy", "France"), "Italy attacked France");
ok($world->war_exists("Russia", "Germany"), "Russia attacked Germany");
$world->elaborate_turn("1970/2");
is($world->get_events("Italy OCCUPIES France", "1970/2"), 1, "Italy occupies France");
is($world->get_nation("Italy")->progress, 0.1, "Italy acquired France progress");
is($world->get_events("WAR BETWEEN Germany AND Russia WON BY Germany", "1970/2"), 1, "WAR BETWEEN Germany AND Russia WON BY Germany");


done_testing();

