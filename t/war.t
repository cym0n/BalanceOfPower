use v5.10;
use BalanceOfPower::World;
use BalanceOfPower::Commands;
use Test::More;


unlink "bop.log";
unlink "bop-dice.log";

#Initialization of test scenario
my @nation_names = ("Italy", "France", "Russia", 
                    "Germany"); 
my $first_year = 1970;
my $world = BalanceOfPower::World->new( first_year => $first_year );

$world->tricks( { "Export quote Italy" => [30],
                  "Export quote France" => [30],
                  "Export quote Russia" => [30],
                  "Export quote Germany" => [30],
                  "Starting production Italy" => [120],
                  "Starting production France" => [120],
                  "Starting production Russia" => [120],
                  "Starting production Germany" => [120],
                  "Delta production Italy" => [(0) x 20],
                  "Delta production France" => [(0) x 20],
                  "Delta production Russia" => [(0) x 20],
                  "Delta production Germany" => [(0) x 20],
                  "Crisis action choose" => [(5) x 20],
                  "War risiko: throw for attacker Italy" => [(6) x 20],
                  "War risiko: throw for defender France" => [(1) x 20],
                  "War risiko: throw for attacker Russia" => [(1) x 20],
                  "War risiko: throw for defender Germany" => [(6) x 20],
              });  
$world->init_random(\@nation_names, { alliances => 0,
                                      trades => 0});
$world->freeze_decisions(1);
#$world->autoplay(1);
#$world->elaborate_turn("1970/1");
#$world->autoplay(0);

#Initialization of commands
my $commands = BalanceOfPower::Commands->new( world => $world );
$commands->init();
$commands->init_game(1);
my $result;

$world->add_crisis(BalanceOfPower::Relations::Crisis->new( node1 => 'Italy', node2 => 'France' ));
$world->get_nation("Italy")->army(6);
$world->get_nation("Italy")->internal_disorder(0);
$world->get_nation("Germany")->army(6);
$world->get_nation("Germany")->internal_disorder(0);
$world->get_nation("Russia")->army(6);
$world->get_nation("Russia")->internal_disorder(0);
$world->get_nation("France")->army(6);
$world->get_nation("France")->internal_disorder(0);
$world->occupy("Germany", [ "Italy" ], "Italy", 1);
$world->occupy("Russia", [ "France" ], "France", 1);
$world->situation_clock();
$world->order("DECLARE WAR TO France");
$world->elaborate_turn("1970/1");
ok($world->war_exists("Italy", "France"), "Italy attacked France");
ok($world->war_exists("Russia", "Germany"), "Russia attacked Germany");
$world->elaborate_turn("1970/2");
is($world->get_events("Italy OCCUPIES France", "1970/2"), 1, "Italy occupies France");
is($world->get_events("WAR BETWEEN Germany AND Russia WON BY Germany", "1970/2"), 1, "WAR BETWEEN Germany AND Russia WON BY Germany");


done_testing();

