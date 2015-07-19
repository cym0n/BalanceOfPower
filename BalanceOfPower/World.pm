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
    default => []
);
has traderoutes => (
    is => 'rw',
    default => []
);
has diplomatic_relations => (
    is => 'rw',
    default => []
);
has statistics => (
    is => 'rw',
    default => {}
);
has events => (
    is => 'rw',
    default => {}
);


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

