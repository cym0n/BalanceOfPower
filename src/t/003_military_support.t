use v5.10;
use lib "lib";
use BalanceOfPower::World;
use BalanceOfPower::Commands;
use Test::More;

#Initialization of test scenario
my @nation_names = ("Italy", "France", "United Kingdom", "Russia", 
                    "Germany"); 
my $first_year = 1970;
my $world = BalanceOfPower::World->new( first_year => $first_year );
$world->init_random('nations-test1.txt', 'borders-test1.txt', { alliances => 0});
$world->autoplay(1);
$world->elaborate_turn("1970/1");
$world->autoplay(0);

#Initialization of commands
my $commands = BalanceOfPower::Commands->new( world => $world );
$commands->init();
$commands->init_game(1);
my $result;



my $germany_diplomacy = $world->diplomacy_exists("Italy", "Germany");
$germany_diplomacy->factor(90);
$world->get_nation("Italy")->army(15);
$world->order("MILITARY SUPPORT Germany");
$world->elaborate_turn("1970/2");
is($world->get_nation("Italy")->army(), 11, "Army of Italy decremented for support");
ok($world->supported("Germany"), "Germany has a support");

$world->get_nation("Germany")->army(7);
$world->get_nation("France")->army(10);
$world->player_nation("France");
$world->order("DECLARE WAR TO Germany");
$world->tricks( { "War risiko: throw for attacker France" => [6, 6, 6],
                  "War risiko: throw for defender Germany" => [1, 1, 1]
              });  
$world->forced_advisor("Noone");
my $france_diplomacy = $world->diplomacy_exists("Italy", "France");
$france_diplomacy->factor(65);
$world->elaborate_turn("1970/3");
is($world->get_nation("Germany")->army(), 6, "Army decreased the right way for Germany");
my $sups = $world->supported("Germany");
is($sups->army, 2, "Italian support decreased the right way for Germany");
is($france_diplomacy->factor, 63, "Diplomacy changed between Italy and France");

$world->player_nation("Italy");
$world->get_nation("Italy")->army(2);
my $uk_diplomacy = $world->diplomacy_exists("Italy", "United Kingdom");
$uk_diplomacy->factor(90);
$commands->query("MILITARY SUPPORT United Kingdom");
$result = $commands->orders();
is($result->{status}, -1, "Command elaborated: MILITARY SUPPORT (not allowed)");
$world->get_nation("Italy")->army(15);
$commands->query("MILITARY SUPPORT United Kingdom");
$result = $commands->orders();
is($result->{status}, 1, "Command elaborated: MILITARY SUPPORT (allowed)");
$world->order(undef);
$world->player_nation("France");
$world->get_nation("Italy")->army(3);
$world->forced_advisor("military");
$world->only_one_nation_acting("Italy");
$world->elaborate_turn("1970/4");
is($world->get_events("MILITARY SUPPORT FOR Germany STOPPED BY Italy", "1970/4"), 1, "MILITARY SUPPORT FOR Germany STOPPED BY Italy");
is($world->get_nation("Italy")->army(), 5, "Italian army merged with returned support");






done_testing();
