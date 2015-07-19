package BalanceOfPower::World;

use strict;
use v5.10;

use Moo;

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw(prev_year next_year random random10 get_year_turns);
use BalanceOfPower::Nation;
use BalanceOfPower::TradeRoute;
use BalanceOfPower::Friendship;


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
        register_event($event);
        $n1->register_event($event);
        $n2->register_event($event);
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
