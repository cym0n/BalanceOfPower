package BalanceOfPower::World;

use strict;
use v5.10;

use Moo;

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
    my $n = shift;
    my @nations = grep { $_->name eq $n } @{$self->nations};
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

#Just set current year for nations and set wealth to zero
sub start_turn
{
    my $self = shift;
    my $turn = shift;
    $self->current_year($turn);
    foreach my $n (@{$self->nations})
    {
        $n->current_year($turn);
        $n->wealth(0);
    }

}

#Say the value of starting production used to calculate production for a turn.
#Usually is just the value of production the turn before, but if rebels won a civil war it has to be undef to allow a totally random generation of production.
sub get_base_production
{
    my $self = shift;
    my $nation = $self->get_nation(shift);
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
    my $nation = $self->get_nation(shift);
    my $value = shift;
    $nation->production($value);
    $self->set_statistics_value($nation, 'production', $value);
    $self->set_statistics_value($nation, 'debt', $nation->debt);
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
    }sub generate_traderoute
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    my $added = shift;
    my $factor1 = random(MIN_TRADEROUTE_GAIN, MAX_TRADEROUTE_GAIN);
    my $factor2 = random(MIN_TRADEROUTE_GAIN, MAX_TRADEROUTE_GAIN);
    push @{$self->trade_routes}, BalanceOfPower::TradeRoute->new( node1 => $node1, node2 => $node2,
                                         factor1 => $factor1, factor2 => $factor2); 
    if($added)
    {
        my $n1 = $self->get_nation($node1);
        my $n2 = $self->get_nation($node2);
        $n1->subtract_production('export', ADDING_TRADEROUTE_COST);
        $n2->subtract_production('export', ADDING_TRADEROUTE_COST);
        change_diplomacy($node1, $node2, TRADEROUTE_DIPLOMACY_FACTOR);
        my $event = "TRADEROUTE ADDED: $node1<->$node2";
        $self->register_event($event);
        $n1->register_event($event);
        $n2->register_event($event);
    }
               
}
sub delete_route
{
    my $self = shift;
    my $node1 = shift;;
    my $node2 = shift;
    my $n1 = $self->get_nation($node1);
    my $n2 = $self->get_nation($node2);
    
    @{$self->trade_routes} = grep { ! $_->is_between($node1, $node2) } @{$self->trade_routes};
    my $event = "TRADEROUTE DELETED: $node1<->$node2";
    $self->register_event($event);
    $n1->register_event($event);
    $n2->register_event($event);
    $self->change_diplomacy($node1, $node2, -1 * TRADEROUTE_DIPLOMACY_FACTOR);
}
sub suitable_route_creator
{
    my $self = shift;
    my $nation = $self->get_nation( shift );
    return 0 if($nation->production < ADDING_TRADEROUTE_COST);
    return 0 if($nation->internal_disorder_status eq 'Civil war');


}
sub suitable_new_route
{
    my $self = shift;
    my $node1 = $self->get_nation( shift );
    my $node2 = $self->get_nation( shift );
    return 0 if($self->route_exists($node1->name, $node2->name));
    if($self->diplomacy_status($node1->name, $node2->name) ne 'HATE')
    {
        if($self->suitable_route_creator($node2->name))
        {
            return 1;
        }
    }
    else
    {
        $self->register_event($node1->name . " AND " . $node2->name . " REFUSED TO OPEN A TRADEROUTE");
        return 0;
    }
}
sub route_exists
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    foreach my $r (@{$self->trade_routes})
    {
        return 1 if($r->is_between($node1, $node2));
    }
    return 0;
}
sub routes_for_node
{
    my $self = shift;
    my $node = shift;
    my @routes;
    foreach my $r (@{$self->trade_routes})
    {
        if($r->has_node($node))
        {
             push @routes, $r;
        }
    }
    return @routes;
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
    my $nation = $self->get_nation( shift );
    my $delta_disorder = shift;
    my $government_fight = shift;
    my $rebels_fight = shift;
    if($nation->internal_disorder > INTERNAL_DISORDER_TERRORISM_LIMIT && $nation->internal_disorder < INTERNAL_DISORDER_CIVIL_WAR_LIMIT)
    {
        $nation->add_internal_disorder($delta_disorder);
        $nation->calculate_disorder();
        $self->set_statistics_value($nation, 'internal disorder', $nation->internal_disorder);
    }
    elsif($nation->internal_disorder_status eq 'Civil war')
    {
        my $winner = $nation->fight_civil_war($government_fight, $rebels_fight);
        $self->set_statistics_value($nation, 'internal disorder', $nation->internal_disorder);
        if($winner eq 'rebels')
        {
            return "REVOLUTION";
        }
    }
    return undef;
}
sub new_government
{
    my $self = shift;
    my $nation = $self->get_nation( shift );
    $nation->new_government({ government_strength => random(0, 100), random(0, 100)});
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
