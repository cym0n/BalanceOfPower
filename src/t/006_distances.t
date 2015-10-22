use lib "lib";
use BalanceOfPower::World;
use Test::More;

#Initialization of test scenario
my $first_year = 1970;
my $world = BalanceOfPower::World->new( first_year => $first_year );
$world->init_random('nations-test1.txt', 'borders-test1.txt',
                   );
is($world->distance("Italy", "United Kingdom"), 2, "Italy - United Kingdom: 2");
is($world->distance("France", "United Kingdom"), 2, "France - United Kingdom: 2");
is($world->distance("Germany", "United Kingdom"), 1, "Germany - United Kingdom: 1");


done_testing();

