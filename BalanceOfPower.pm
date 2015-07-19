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
        wars();
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
        my $nation = get_nation($n);
        if($nation->internal_disorder > INTERNAL_DISORDER_TERRORISM_LIMIT && $nation->internal_disorder < INTERNAL_DISORDER_CIVIL_WAR_LIMIT)
        {
            $nation->add_internal_disorder(random(MIN_ADDED_DISORDER, MAX_ADDED_DISORDER));
        }
        elsif($nation->internal_disorder_status eq 'Civil war')
        {
            my $winner = $nation->fight_civil_war(random(0, 100), random(0, 100));
            if($winner eq 'rebels')
            {
                $nation->new_government({ government_strength => random10(MIN_GOVERNMENT_STRENGTH, MAX_GOVERNMENT_STRENGTH) });
            }
            
        }
        $nation->calculate_disorder();
        $statistics{$current_year}->{$n}->{'internal disorder'} = $nation->internal_disorder;
    }
}

sub wars
{
    foreach my $n (@nation_names)
    {
        my $nation = get_nation($n);
        $statistics{$current_year}->{$n}->{'army'} = $nation->army;
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
            print_overall_statistics();
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
                print_nation_statistics($good_nation[0]);
            }
        }
        elsif($query =~ m/status:(.*)/)
        {
            my @good_nation = grep { $_ eq $1 } @nation_names; 
            if(@good_nation > 0)
            { 
                say $good_nation[0] . " - STATUS";
                say "=====\n";
                my $nation = get_nation($good_nation[0]);
                $nation->print;
            }
        }
        elsif($query =~ m/diplomacy:(.*)/)
        {
            my @good_nation = grep { $_ eq $1 } @nation_names; 
            if(@good_nation > 0)
            { 
                print_diplomacy($good_nation[0]);
            }
        }


        else
        {
            my @good_nation = grep { $_ eq $query } @nation_names; 
            my @good_year = grep { $_ eq $query } ($first_year..$last_year);
            if(@good_nation > 0)
            { 
                my $nation = get_nation($query);
                say "\n=====\n";
                $nation->print;
                print_nation_statistics($query);
            }
            elsif(@good_year > 0)
            {
                print_year_statistics($query);
            }
        }
    }
}



sub print_diplomacy
{
    my $n = shift;
    foreach my $f (sort {$a->factor <=> $b->factor} @diplomatic_relations)
    {
        if($f->has_node($n))
        {
            $f->print($n);
        }
    }
}



sub get_nation
{
    my $name = shift;
    foreach my $n (@nations)
    {
        return $n if($n->name eq $name);
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
sub print_nation_statistics
{
    my $nation = shift;
    my @good = grep { $_ eq $nation } @nation_names; 
    if(@good == 0)
    {
      say "Bad nation";
      return;
    }   
    print "\n";
    print_nation_statistics_header();
    foreach my $y ($first_year..$last_year)
    {
        foreach my $t (get_year_turns($y))
        {
            print_nation_statistics_line($nation, $t);
        }
    }
}
sub print_nation_statistics_header
{
    say "Year\tProd.\tWealth\tGrowth\tDelta\tDebt\tDisor.\tArmy";
}
sub print_nation_statistics_line
{
    my $nation = shift;
    my $y = shift;
    print "$y\t";
    print $statistics{$y}->{$nation}->{'production'} . "\t";
    print $statistics{$y}->{$nation}->{'wealth'} . "\t";
    if($statistics{$y}->{$nation}->{'production'} <= 0)
    {
        print "X\t";
    }
    else
    {
        print int(($statistics{$y}->{$nation}->{'wealth'} / $statistics{$y}->{$nation}->{'production'}) * 100) / 100 . "\t";
    }
    print $statistics{$y}->{$nation}->{'wealth'} - $statistics{$y}->{$nation}->{'production'} . "\t";
    print $statistics{$y}->{$nation}->{'debt'} ."\t";
    print $statistics{$y}->{$nation}->{'internal disorder'} . "\t";
    print $statistics{$y}->{$nation}->{'army'} . "\t";
    print "\n";
}
sub print_year_statistics
{
    my $y = shift;
    say "Year\tProd.\tWealth\tInt.Dis";
    foreach my $t (get_year_turns($y))
    {
        my ($prod, $wealth, $disorder) = medium_statistics($t);
        say "$t\t$prod\t$wealth\t$disorder";
    }
    print "\n";
    foreach my $n (@nation_names)
    {
        say "$n:";
        print_nation_statistics_header();
        foreach my $t (get_year_turns($y))
        {
            print_nation_statistics_line($n, $t);
        }
        print "\n";
    }
    say "Events of the year:";
    foreach my $t (get_year_turns($y))
    {
        say " - $t";
        foreach my $e (@{$events{$t}})
        {
            say " " . $e;
        }
    }
}
sub print_overall_statistics
{
    say "Overall medium values";
    say "Year\tProd.\tWealth\tInt.Dis";
    foreach my $y ($first_year..$last_year)
    {
        my ($prod, $wealth, $disorder) = medium_statistics($y);
        say "$y\t$prod\t$wealth\t$disorder";
    }
}
sub medium_statistics
{
    my $year = shift;
    my $total_production;
    my $total_wealth;
    my $total_disorder;
    foreach my $t (get_year_turns($year))
    {
        foreach my $n (@nation_names)
        {
            $total_production += $statistics{$t}->{$n}->{production};
            $total_wealth += $statistics{$t}->{$n}->{wealth};
            $total_disorder += $statistics{$t}->{$n}->{'internal disorder'};
        }
    }
    my $medium_production = int(($total_production / @nations)*100)/100;
    my $medium_wealth = int(($total_wealth / @nations)*100)/100;
    my $medium_disorder = int(($total_disorder / @nations)*100)/100;
    return ($medium_production, $medium_wealth, $medium_disorder);
}




