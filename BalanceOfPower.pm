package BalanceOfPower;
use v5.10;

use IO::Prompt;
use List::Util qw(shuffle);
use Data::Dumper;

use BalanceOfPower::Utils qw(prev_year next_year random random10 get_year_turns);
use BalanceOfPower::Constants ':all';
use BalanceOfPower::World;
use BalanceOfPower::Nation;
use BalanceOfPower::TradeRoute;
use BalanceOfPower::Friendship;

use strict;

#Initial status
my @nation_names = ("Italy", "France", "United Kingdom", "Russia", "Germany", "Spain", "Greece",
               "Switzerland", "Finland", "Sweden", "Norway", "Netherlands", "Belgium"); 
my $first_year = 1970;
my $last_year = 1995;

#Persistent objects
my $current_year;

#Support objects
my @decisions;

#Init
my $world = BalanceOfPower::World->new();
$world->init_random(@nation_names);

#History generation
for($first_year..$last_year)
{
    my $y = $_;
    foreach my $t (get_year_turns($y))
    {
        $current_year = $t;
        init_year();
        execute_decisions();
        $world->economy();
        internal_conflict();
        $world->wars();
    }
}

#Interface
say "=======\n\n\n";
interface();



sub init_year
{
    my $year = $current_year;
    say "-------";
    say $current_year;
    say "-------";

    $world->start_turn($current_year);
    foreach my $n (@nation_names)
    {
        $world->set_production($n, calculate_production($world->get_base_production($n)));
    }
    @decisions = $world->decisions();
}

sub execute_decisions
{   
    my @route_adders = ();
    foreach my $d (@decisions)
    {
        if($d =~ /^(.*): DELETE TRADEROUTE (.*)->(.*)$/)
        {
            $world->delete_route($2, $3);
        }
        elsif($d =~ /^(.*): ADD ROUTE$/)
        {
            push @route_adders, $1;
        }
        elsif($d =~ /^(.*): LOWER DISORDER$/)
        {
           $world->lower_disorder($1);
        }
        elsif($d =~ /^(.*): BUILD TROOPS$/)
        {
           $world->build_troops($1);
        }
    }
    manage_route_adding(@route_adders);
}

sub manage_route_adding
{
    my @route_adders = @_;
    if(@route_adders > 1)
    {
       @route_adders = shuffle @route_adders; 
       my $done = 0;
       while(! $done)
       {
            my $node1 = shift @route_adders;
            if($world->suitable_route_creator($node1))
            {
                if(@route_adders == 0)
                {
                    $world->register_event("TRADEROUTE CREATION FAILED FOR LACK OF PARTNERS", $node1);
                    $done = 1;
                } 
                else
                {
                    my $complete = 0;
                    foreach my $second (@route_adders)
                    {
                        if($world->suitable_new_route($node1, $second))
                        {
                            @route_adders = grep { $_ ne $second } @route_adders;
                            $world->generate_route($node1, $second, 1);
                            $complete = 1;
                        }
                        last if $complete;
                    }     
                    if($complete == 0)
                    {
                        $world->register_event("TRADEROUTE CREATION FAILED FOR LACK OF PARTNERS", $node1);
                    }
                }
            }
            else
            {
                $world->register_event("TRADEROUTE CREATION NOT POSSIBLE", $node1);
            }
            $done = 1 if(@route_adders == 0);
       }
    }
}


sub internal_conflict
{
    foreach my $n (@nation_names)
   {
        my $result = $world->manage_internal_disorder($n, 
                                                      random(MIN_ADDED_DISORDER, MAX_ADDED_DISORDER),
                                                      random(0, 100), random(0, 100));
        if($result eq "REVOLUTION")
        {
            $world->new_government($n);
        }        
    }
}



sub interface
{
    say "Retrieve informations about history";
    say "Commands are: overall, nations, year, history:[nation name], status:[nation name], [year], commands, quit";
    my $continue = 1;
    while($continue)
    {
        my $query = prompt "?";
        if($query eq "quit") { $continue = 0 }
        elsif($query eq "overall")
        {
            say $world->print_overall_statistics();
        }
        elsif($query eq "nations")
        {
            for(@nation_names) {say $_} ;
        }
        elsif($query eq "years")
        {
            say "From $first_year to $last_year";
        }
        elsif($query eq "commands")
        {
            say "Commands are: overall, nations, [nation name], [year], commands, quit";
        }
        elsif($query =~ m/history:(.*)/)
        {
            my @good_nation = grep { $_ eq $1 } @nation_names; 
            if(@good_nation > 0)
            { 
                say $good_nation[0] . " - HISTORY";
                say "=====\n";
                say $world->print_nation_statistics($good_nation[0], $first_year, $last_year);
            }
        }
        elsif($query =~ m/status:(.*)/)
        {
            my @good_nation = grep { $_ eq $1 } @nation_names; 
            if(@good_nation > 0)
            { 
                say $good_nation[0] . " - STATUS";
                say "=====\n";
                say $world->print_nation($good_nation[0]);
            }
        }
        elsif($query =~ m/diplomacy:(.*)/)
        {
            my @good_nation = grep { $_ eq $1 } @nation_names; 
            if(@good_nation > 0)
            { 
                say $world->print_diplomacy($good_nation[0]);
            }
        }
        else
        {
            my @good_nation = grep { $_ eq $query } @nation_names; 
            my @good_year = grep { $_ eq $query } ($first_year..$last_year);
            if(@good_nation > 0)
            { 
                say "\n=====\n";
                say $world->print_nation($query);
                say $world->print_nation_statistics($query);
            }
            elsif(@good_year > 0)
            {
                say $world->print_year_statistics($query);
            }
        }
    }
}

sub calculate_production
{
    my $production = shift;
    my $next = 0;
    if($production != undef)
    {
        $next = $production + random10(MIN_DELTA_PRODUCTION, MAX_DELTA_PRODUCTION);
    }
    else
    {
        $next = random10(MIN_STARTING_PRODUCTION, MAX_STARTING_PRODUCTION);
    }
    if($next < 0)
    {
        $next = 0;
    }
    return $next;
}

