package BalanceOfPower::World;

use strict;
use v5.10;

use Moo;
use List::Util qw(shuffle);

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw(prev_year next_year random random10 get_year_turns);
use BalanceOfPower::Nation;
use BalanceOfPower::TradeRoute;
use BalanceOfPower::Friendship;

has current_year => (
    is => 'rw'
);
has nations => (
    is => 'rw',
    default => sub { [] }
);

has diplomatic_relations => (
    is => 'rw',
    default => sub { [] }
);

with 'BalanceOfPower::Role::Historian';
with 'BalanceOfPower::Role::Merchant';


sub get_nation
{
    my $self = shift;
    my $nation = shift;
    my @nations = grep { $_->name eq $nation } @{$self->nations};
    if(@nations > 0)
    {
        return $nations[0];
    }
    else
    {
        return undef;
    }
}


#Initial values, randomly generated
sub init_random
{
    my $self = shift;
    my @nations = @_;

    my %routes_counter;
    foreach my $n (@nations)
    {
        say "Working on $n";
        my $export_quote = random10(MIN_EXPORT_QUOTE, MAX_EXPORT_QUOTE);
        say "  export quote: $export_quote";
        my $government_strength = random10(MIN_GOVERNMENT_STRENGTH, MAX_GOVERNMENT_STRENGTH);
        push @{$self->nations}, BalanceOfPower::Nation->new( name => $n, export_quote => $export_quote, government_strength => $government_strength);
        $routes_counter{$n} = 0 if(! exists $routes_counter{$n});
        my $how_many_routes = random(MIN_STARTING_TRADEROUTES, MAX_STARTING_TRADEROUTES);
        say "  routes to generate: $how_many_routes [" . $routes_counter{$n} . "]";
        my @my_names = @nations;
        @my_names = grep { $_ ne $n } @my_names;
        while($routes_counter{$n} < $how_many_routes)
        {
            my $second_node = $my_names[rand @my_names];
            if($second_node ne $n && ! $self->route_exists($n, $second_node))
            {
                say "  creating trade route to $second_node";
                @my_names = grep { $_ ne $second_node } @my_names;
                $self->generate_traderoute($n, $second_node, 0);
                $routes_counter{$n}++;
                $routes_counter{$second_node} = 0 if(! exists $routes_counter{$second_node});
                $routes_counter{$second_node}++;
            }
        }
        foreach my $n2 (@nations)
        {
            if($n ne $n2)
            {
                my $rel = new BalanceOfPower::Friendship( node1 => $n,
                                                          node2 => $n2,
                                                          factor => random(0,100));
                push @{$self->diplomatic_relations}, $rel;
            }
        }
    }
}
sub init_year
{
    my $self = shift;
    my $turn = shift;
    $self->current_year($turn);
    foreach my $n (@{$self->nations})
    {
        $n->current_year($turn);
        $n->wealth(0);
        $self->set_production($n, $self->calculate_production($n));
    }
}

#Say the value of starting production used to calculate production for a turn.
#Usually is just the value of production the turn before, but if rebels won a civil war it has to be undef to allow a totally random generation of production.
sub get_base_production
{
    my $self = shift;
    my $nation = shift;
    my $statistics_production = $self->get_statistics_value(prev_year($nation->current_year), $nation->name, 'production'); 
    if($statistics_production)
    {
        my @newgov = $nation->get_events("NEW GOVERNMENT CREATED", prev_year($nation->current_year));
        if(@newgov > 0)
        {
            return undef;
        }
        else
        {
            return $statistics_production;
        }
    }
    else
    {
        return undef;
    }
}

#Production has to be configured at the start of every turn
sub set_production
{
    my $self = shift;
    my $nation = shift;
    my $value = shift;
    $nation->production($value);
    $self->set_statistics_value($nation, 'production', $value);
    $self->set_statistics_value($nation, 'debt', $nation->debt);
}

sub calculate_production
{
    my $self = shift;
    my $n = shift;
    my $production = $self->get_base_production($n);
    my $next = 0;
    if($production)
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
sub economy
{
    my $self = shift;
    $self->calculate_internal_wealth();
    $self->calculate_wealth_from_export();
    $self->calculate_remains_conversion();
    foreach my $n (@{$self->nations})
    {
        $self->set_statistics_value($n, 'wealth', $n->wealth);
    }
}
sub calculate_internal_wealth
{
    my $self = shift;
    foreach my $n (@{$self->nations})
    {
        $n->calculate_internal_wealth();
    }
}
sub calculate_wealth_from_export
{
    my $self = shift;
    foreach my $n (@{$self->nations})
    {
        $n->calculate_trading($self);
        $n->convert_remains();
    }
}
sub calculate_remains_conversion
{
    my $self = shift;
    foreach my $n (@{$self->nations})
    {
        $n->convert_remains();
    }
}




sub decisions
{
    my $self = shift;
    my @decisions = ();
    foreach my $nation (@{$self->nations})
    {
        my $decision = $nation->decision();
        if($decision)
        {
            say $decision;
            push @decisions, $decision;
        }
    }
    return @decisions;
}
sub execute_decisions
{   
    my $self = shift;
    my @decisions = $self->decisions;
    my @route_adders = ();
    foreach my $d (@decisions)
    {
        if($d =~ /^(.*): DELETE TRADEROUTE (.*)->(.*)$/)
        {
            $self->delete_route($2, $3);
        }
        elsif($d =~ /^(.*): ADD ROUTE$/)
        {
            push @route_adders, $1;
        }
        elsif($d =~ /^(.*): LOWER DISORDER$/)
        {
           $self->lower_disorder($1);
        }
        elsif($d =~ /^(.*): BUILD TROOPS$/)
        {
           $self->build_troops($1);
        }
    }
    $self->manage_route_adding(@route_adders);
}

sub manage_route_adding
{
    my $self = shift;
    my @route_adders = @_;
    if(@route_adders > 1)
    {
       @route_adders = shuffle @route_adders; 
       my $done = 0;
       while(! $done)
       {
            my $node1 = shift @route_adders;
            if($self->suitable_route_creator($node1))
            {
                if(@route_adders == 0)
                {
                    $self->register_event("TRADEROUTE CREATION FAILED FOR LACK OF PARTNERS", $node1);
                    $done = 1;
                } 
                else
                {
                    my $complete = 0;
                    foreach my $second (@route_adders)
                    {
                        if($self->suitable_new_route($node1, $second))
                        {
                            @route_adders = grep { $_ ne $second } @route_adders;
                            $self->generate_route($node1, $second, 1);
                            $complete = 1;
                        }
                        last if $complete;
                    }     
                    if($complete == 0)
                    {
                        $self->register_event("TRADEROUTE CREATION FAILED FOR LACK OF PARTNERS", $node1);
                    }
                }
            }
            else
            {
                $self->register_event("TRADEROUTE CREATION NOT POSSIBLE", $node1);
            }
            $done = 1 if(@route_adders == 0);
       }
    }
}

sub internal_conflict
{
    my $self = shift;
    foreach my $n (@{$self->nations})
    {
        my $result = $self->manage_internal_disorder($n, 
                                                      random(MIN_ADDED_DISORDER, MAX_ADDED_DISORDER),
                                                      random(0, 100), random(0, 100));
        if($result && $result eq "REVOLUTION")
        {
            $n->new_government({ government_strength => random(0, 100), random(0, 100)});
        }        
    }
}

sub lower_disorder
{
    my $self = shift;
    my $n = $self->get_nation( shift );
    $n->lower_disorder();
}
sub build_troops
{
    my $self = shift;
    my $n = $self->get_nation( shift );
    $n->build_troops();
}
sub manage_internal_disorder
{
    my $self = shift;
    my $nation = shift;
    my $delta_disorder = shift;
    my $government_fight = shift;
    my $rebels_fight = shift;
    my $winner = undef;
    if($nation->internal_disorder > INTERNAL_DISORDER_TERRORISM_LIMIT && $nation->internal_disorder < INTERNAL_DISORDER_CIVIL_WAR_LIMIT)
    {
        $nation->add_internal_disorder($delta_disorder);
        $nation->calculate_disorder();
    }
    elsif($nation->internal_disorder_status eq 'Civil war')
    {
        my $winner = $nation->fight_civil_war($government_fight, $rebels_fight);
    }
    $self->set_statistics_value($nation, 'internal disorder', $nation->internal_disorder);
    if($winner && $winner eq "rebels")
    {
        return "REVOLUTION";
    }
    else
    {
        return undef;
    }
}
sub wars
{
    my $self = shift;
    foreach my $n (@{$self->nations})
    {
        $self->set_statistics_value($n, 'army', $n->army);    
    }    
}



sub change_diplomacy
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    my $dipl = shift;
    foreach my $r (@{$self->diplomatic_relations})
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
                $self->register_event("RELATION BETWEEN $node1 AND $node2 CHANGED FROM $present_status TO $actual_status");
            }
        }
    }
}
sub diplomacy_status
{
    my $self = shift;
    my $n1 = shift;
    my $n2 = shift;
    foreach my $r (@{$self->diplomatic_relations})
    {
        if($r->is_between($n1, $n2))
        {
            return $r->status;
        }
    }
}
sub diplomacy_for_node
{
    my $self = shift;
    my $node = shift;
    my %relations;
    foreach my $r (@{$self->diplomatic_relations})
    {
        if($r->has_node($node))
        {
             $relations{$r->destination($node)} = $r->factor;
        }
    }
    return %relations;;
}
sub print_diplomacy
{
    my $self = shift;
    my $n = shift;
    my $out;
    foreach my $f (sort {$a->factor <=> $b->factor} @{$self->diplomatic_relations})
    {
        if($f->has_node($n))
        {
            $out .= $f->print($n) . "\n";
        }
    }
    return $out;
}



1;
