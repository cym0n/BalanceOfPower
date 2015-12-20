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
ok($treaty, "TREATY COM WITH: Italy and Germany have a nag treaty");

done_testing();

