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
        domestic_economy();
        foreign_economy();
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
            delete_route($2, $3);
        }
        elsif($d =~ /^(.*): ADD ROUTE$/)
        {
            push @route_adders, $1;
        }
        elsif($d =~ /^(.*): LOWER DISORDER$/)
        {
           my $n = get_nation($1);
           $n->lower_disorder();
        }
        elsif($d =~ /^(.*): BUILD TROOPS$/)
        {
           my $n = get_nation($1);
           $n->build_troops();
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
            my $n1 = get_nation($node1);
            if($n1->production >= ADDING_TRADEROUTE_COST)
            {
                if(@route_adders == 0)
                {
                    $n1->register_event("TRADEROUTE CREATION FAILED FOR LACK OF PARTNERS");
                    $done = 1;
                } 
                else
                {
                    my $complete = 0;
                    foreach my $second (@route_adders)
                    {
                        if(! route_exists($node1, $second))
                        {
                            if(diplomacy_status($node1, $second) ne 'HATE')
                            {
                                my $n2 = get_nation($second);
                                if($n2->production_for_export >= ADDING_TRADEROUTE_COST)
                                {
                                    @route_adders = grep { $_ ne $second } @route_adders;
                                    generate_route($node1, $second, 1);
                                    $complete = 1;
                                }
                                else
                                {
                                }
                            }
                            else
                            {
                                register_event("$node1 AND $second REFUSED TO OPEN A TRADEROUTE");
                            }
                        }
                        else
                        {
                        }
                        last if($complete);
                    }
                    if($complete == 0)
                    {
                        $n1->register_event("TRADEROUTE CREATION FAILED FOR LACK OF PARTNERS");
                    }
                }
            }
            else
            {
                $n1->register_event("TRADEROUTE CREATION FAILED FOR LACK OF RESOURCES");
            }
            $done = 1 if(@route_adders == 0);
       }
    
    }
}

sub domestic_economy
{
   foreach my $n (@nation_names)
   {
        my $nation = get_nation($n);
        $nation->calculate_internal_wealth();
   }
}


sub foreign_economy
{
   foreach my $n (@nation_names)
   {
        my $nation = get_nation($n);
        $nation->calculate_trading(routes_for_node($n), diplomacy_for_node($n));
        $nation->convert_remains();
        $statistics{$current_year}->{$n}->{'wealth'} = $nation->wealth;
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

sub generate_route
{
    my $node1 = shift;
    my $node2 = shift;
    my $added = shift;
    my $factor1 = random(MIN_TRADEROUTE_GAIN, MAX_TRADEROUTE_GAIN);
    my $factor2 = random(MIN_TRADEROUTE_GAIN, MAX_TRADEROUTE_GAIN);
    push @trade_routes, BalanceOfPower::TradeRoute->new( node1 => $node1, node2 => $node2,
                                         factor1 => $factor1, factor2 => $factor2); 
    if($added)
    {
        my $n1 = get_nation($node1);
        my $n2 = get_nation($node2);
        $n1->subtract_production('export', ADDING_TRADEROUTE_COST);
        $n2->subtract_production('export', ADDING_TRADEROUTE_COST);
        change_diplomacy($node1, $node2, TRADEROUTE_DIPLOMACY_FACTOR);
        my $event = "TRADEROUTE ADDED: $node1<->$node2";
        register_event($event);
        $n1->register_event($event);
        $n2->register_event($event);
    }
               
}

sub route_exists
{
    my $node1 = shift;
    my $node2 = shift;
    foreach my $r (@trade_routes)
    {
        return 1 if($r->is_between($node1, $node2));
    }
    return 0;
}
sub routes_for_node
{
    my $node = shift;
    my @routes;
    foreach my $r (@trade_routes)
    {
        if($r->has_node($node))
        {
             push @routes, $r;
        }
    }
    return \@routes;
}
sub delete_route
{
    my $node1 = shift;;
    my $node2 = shift;
    my $n1 = get_nation($node1);
    my $n2 = get_nation($node2);
    
    @trade_routes = grep { ! $_->is_between($node1, $node2) } @trade_routes;
    my $event = "TRADEROUTE DELETED: $node1<->$node2";
    register_event($event);
    $n1->register_event($event);
    $n2->register_event($event);
    change_diplomacy($node1, $node2, -1 * TRADEROUTE_DIPLOMACY_FACTOR);
}

sub diplomacy_for_node
{
    my $node = shift;
    my %relations;
    foreach my $r (@diplomatic_relations)
    {
        if($r->has_node($node))
        {
             $relations{$r->destination($node)} = $r->factor;
        }
    }
    return \%relations;;
}
sub change_diplomacy
{
    my $node1 = shift;
    my $node2 = shift;
    my $dipl = shift;
    foreach my $r (@diplomatic_relations)
    {
        if($r->is_between($node1, $node2))
        {
            my $present_status = $r->status;
            $r->factor($r->factor + $dipl);
            $r->factor(0) if $r->factor < 0;
            $r->factor(100) if $r->factor > 100;
            my $actual_status = $r->status;
            if($present_status ne $actual_status)
            {
                register_event("RELATION BETWEEN $node1 AND $node2 CHANGED FROM $present_status TO $actual_status");
            }
        }
    }
}
sub diplomacy_status
{
    my $n1 = shift;
    my $n2 = shift;
    foreach my $r (@diplomatic_relations)
    {
        if($r->is_between($n1, $n2))
        {
            return $r->status;
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

sub register_event
{
    my $event = shift;
    if(! exists $events{$current_year})
    {
        $events{$current_year} = ();
    }
    push @{$events{$current_year}}, $event;
}


