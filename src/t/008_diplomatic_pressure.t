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
my $first_year = 1970;


#Scenario: a neighbor has military support from an enemy nation
my $world = BalanceOfPower::World->new( first_year => $first_year, silent => 1 );
$world->init_random("nations-test1.txt", "borders-test1.txt", 
                    { alliances => 0, trades => 0 });

my @diplomacies = (
    ['Italy', 'Germany', 80],
    ['Italy', 'France', 50], #We'll do pressure on this
    ['Italy', 'United Kingdom', 76],
    ['Italy', 'Russia', 22],
    ['France', 'Germany', 50],
    ['France', 'United Kingdom', 50],
    ['France', 'Russia', 50],
);

for(@diplomacies)
{
    $world->set_diplomacy($_->[0], $_->[1], $_->[2]);
}
$world->player_nation("Italy");
$world->player("Tester");
$world->forced_advisor("noone");
$world->order("DIPLOMATIC PRESSURE ON France");
$world->pre_decisions_elaborations('1970/1');
$world->get_nation("Italy")->prestige(15);
$world->post_decisions_elaborations();
is($world->diplomacy_exists("France", "Italy")->factor, 44, "France<->Italy: 44");
is($world->diplomacy_exists("France", "Germany")->factor, 44, "France<->Germany: 44");
is($world->diplomacy_exists("France", "United Kingdom")->factor, 44, "France<->United Kingdom: 44");
is($world->diplomacy_exists("France", "Russia")->factor, 50, "France<->Russia: 50");

done_testing();
