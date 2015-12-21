use v5.10;
use lib "lib";
use BalanceOfPower::World;
use BalanceOfPower::Commands;
use Test::More;

#Initialization of test scenario
# Italy
# France
# United Kingdom
# Russia
# Germany
#
# Orders tested here:
#   * ECONOMIC AID
#   * TREATY COM
#   * AID INSURGENTS IN
#   * MILITARY AID FOR 


my $first_year = 1970;


#Scenario: a neighbor has military support from an enemy nation
my $world = BalanceOfPower::World->new( first_year => $first_year, silent => 1 );
$world->tricks( { "Export quote Italy" => [50],
                  "Export quote Germany" => [50],
              });
$world->init_random("nations-test1.txt", "borders-test1.txt", 
                    { alliances => 0, trades => 0 });

$world->player_nation("Italy");
$world->player("Tester");
$world->forced_advisor("noone");

my @internal_event;
my @remain_event;
my @disorder_event;

$world->pre_decisions_elaborations('1970/1');
$world->set_diplomacy("Italy", "Germany", 60);
$world->get_nation("Italy")->production(200);
$world->get_nation("Germany")->production(100);
$world->ia_orders( [ "Italy: ECONOMIC AID FOR Germany" ] );
$world->post_decisions_elaborations();
@remain_event = $world->get_nation("Italy")->get_events("REMAIN", "1970/1");
is($remain_event[0], "REMAIN 70", "ECONOMIC AID: Italy paid for economic aid");
@internal_event = $world->get_nation("Germany")->get_events("INTERNAL", "1970/1");
@remain_event = $world->get_nation("Germany")->get_events("REMAIN", "1970/1");
is($internal_event[0], "INTERNAL 78", "ECONOMIC AID: Domestic production incremented by italian economic aid");
is($remain_event[0], "REMAIN 78", "ECONOMIC AID: Export production incremented by italian economic aid");
is($world->diplomacy_exists("Italy", "Germany")->factor, 69, "ECONOMIC AID: Italy<->Germany diplomacy: 69");

$world->generate_traderoute("Italy", "Germany", 0);
$world->pre_decisions_elaborations('1970/2');
$world->set_diplomacy("Italy", "Germany", 60);
$world->get_nation("Italy")->prestige(20);
$world->ia_orders( [ "Italy: TREATY COM WITH Germany" ] );
$world->post_decisions_elaborations();
my $treaty = $world->exists_treaty_by_type("Italy", "Germany", "commercial");
ok($treaty, "TREATY COM WITH: Italy and Germany have a com treaty");
$world->delete_treaty("Italy", "Germany");
$world->delete_traderoute("Italy", "Germany");

$world->pre_decisions_elaborations('1970/3');
$world->set_diplomacy("Italy", "France", 50);
$world->get_nation("Italy")->production(200);
$world->get_nation("France")->internal_disorder(30);
$world->ia_orders( [ "Italy: AID INSURGENTS IN France" ] );
$world->post_decisions_elaborations();
@remain_event = $world->get_nation("Italy")->get_events("REMAIN", "1970/3");
is($remain_event[0], "REMAIN 75", "AID INSURGENTS: Italy paid the cost to aid insurgents");
@disorder_event = $world->get_nation("France")->get_events("DISORDER CHANGE", "1970/3");
$change = $disorder_event[0];
$change =~ s/DISORDER CHANGE: //;
is($world->get_nation("France")->internal_disorder, 45 + $change, "AID INSURGENTS: internal disorder raised in France");

$world->pre_decisions_elaborations('1970/4');
$world->set_diplomacy("Italy", "Germany", 80);
$world->get_nation("Italy")->production(200);
$world->get_nation("Germany")->army(2);
$world->ia_orders( [ "Italy: MILITARY AID FOR Germany" ] );
$world->post_decisions_elaborations();
@remain_event = $world->get_nation("Italy")->get_events("REMAIN", "1970/4");
is($remain_event[0], "REMAIN 80", "MILITARY AID: Italy paid the cost to military aid Germany");
is($world->get_nation("Germany")->army, 3, "MILITARY AID: Germany has new soldiers");



done_testing();

