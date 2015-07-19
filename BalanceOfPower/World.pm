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
has traderoutes => (
    is => 'rw',
    default => sub { [] }
);
has diplomatic_relations => (
    is => 'rw',
    default => sub { [] }
);
has statistics => (
    is => 'rw',
    default => sub { {} }
);
has events => (
    is => 'rw',
    default => sub { {} }
);

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
            if($second_node ne $n && ! route_exists($n, $second_node))
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
    $self->current_year = $turn;
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
    my $n = get_nation( shift );
    $n->lower_disorder();
}
sub build_troops
{
    my $self = shift;
    my $n = get_nation( shift );
    $n->build_troops();
}



sub generate_traderoute
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    my $added = shift;
    my $factor1 = random(MIN_TRADEROUTE_GAIN, MAX_TRADEROUTE_GAIN);
    my $factor2 = random(MIN_TRADEROUTE_GAIN, MAX_TRADEROUTE_GAIN);
    push @{$self->traderoutes}, BalanceOfPower::TradeRoute->new( node1 => $node1, node2 => $node2,
                                         factor1 => $factor1, factor2 => $factor2); 
    if($added)
    {
        my $n1 = get_nation($node1);
        my $n2 = get_nation($node2);
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
    my $n1 = get_nation($node1);
    my $n2 = get_nation($node2);
    
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
    my $nation = get_nation( shift );
    return 0 if($nation->production < ADDING_TRADEROUTE_COST);
    return 0 if($nation->internal_disorder_status eq 'Civil war');


}
sub suitable_new_route
{
    my $self = shift;
    my $node1 = get_nation( shift );
    my $node2 = get_nation( shift );
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


sub register_event
{
    my $self = shift;
    my $event = shift;
    my $n1 = shift;
    if($n1)
    {
        my $nation = $self->get_nation($n1);
        $nation->register_event($event);
    }
    else
    {
        if(! exists $self->events->{$self->current_year})
        {
            $self->events->{$self->current_year} = ();
        }
        push @{$self->events->{$self->current_year}}, $event;
    }

}
sub get_statistics_value
{
    my $self;
    my $turn;
    my $nation;
    my $value;
    if(exists $self->statistics->{$turn})
    {
        return $self->statistics->{$turn}->{$nation}->{$value};
    }
    else
    {
        return undef;
    }
}
sub set_statistics_value
{
    my $self;
    my $nation;
    my $value_name;
    my $value;
    $self->statistics->{$nation->current_year}->{$nation->name}->{$value_name} = $value;
}


1;
