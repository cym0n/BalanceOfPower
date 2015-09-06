package BalanceOfPower::Role::Merchant;

use strict;
use v5.10;
use Moo::Role;

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw( random );
use BalanceOfPower::Relations::TradeRoute;

requires 'get_nation';
requires 'broadcast_event';
requires 'change_diplomacy';
requires 'diplomacy_status';

has trade_routes => (
    is => 'ro',
    default => sub { BalanceOfPower::Relations::RelPack->new() },
    handles => { add_traderoute => 'add_link',
                 delete_traderoute => 'delete_link',
                 route_exists => 'exists_link',
                 routes_for_node => 'links_for_node',
                 route_destinations_for_node => 'link_destinations_for_node'
    #             print_borders => 'print_links'
               }
);

sub init_trades
{
    my $self = shift;
    my @nations = @{$self->nations};
    my %routes_counter;
    foreach my $n (@nations)
    {
        $routes_counter{$n->name} = 0 if(! exists $routes_counter{$n->name});
        my $how_many_routes = random(MIN_STARTING_TRADEROUTES, MAX_STARTING_TRADEROUTES);
        say "  routes to generate: $how_many_routes [" . $routes_counter{$n->name} . "]";
        my @my_names = @nations;
        @my_names = grep { $_->name ne $n->name } @my_names;
        while($routes_counter{$n->name} < $how_many_routes)
        {
            my $second_node = $my_names[rand @my_names];
            if($second_node->name ne $n->name && ! $self->route_exists($n->name, $second_node->name))
            {
                say "  creating trade route to " . $second_node->name;
                @my_names = grep { $_->name ne $second_node->name } @my_names;
                $self->generate_traderoute($n->name, $second_node->name, 0);
                $routes_counter{$n->name}++;
                $routes_counter{$second_node->name} = 0 if(! exists $routes_counter{$second_node->name});
                $routes_counter{$second_node->name}++;
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
    $self->add_traderoute( 
        BalanceOfPower::Relations::TradeRoute->new( 
            node1 => $node1, node2 => $node2,
            factor1 => $factor1, factor2 => $factor2)); 
    if($added)
    {
        my $n1 = $self->get_nation($node1);
        my $n2 = $self->get_nation($node2);
        $n1->subtract_production('export', ADDING_TRADEROUTE_COST);
        $n2->subtract_production('export', ADDING_TRADEROUTE_COST);
        $self->change_diplomacy($node1, $node2, TRADEROUTE_DIPLOMACY_FACTOR);
        my $event = "TRADEROUTE ADDED: $node1<->$node2";
        $self->broadcast_event($event, $node1, $node2);
    }
               
}
sub delete_route
{
    my $self = shift;
    my $node1 = shift;;
    my $node2 = shift;
    my $n1 = $self->get_nation($node1);
    my $n2 = $self->get_nation($node2);
    $self->delete_traderoute($node1, $node2);
    my $event = "TRADEROUTE DELETED: $node1<->$node2";
    $self->broadcast_event($event, $node1, $node2);
    $self->change_diplomacy($node1, $node2, -1 * TRADEROUTE_DIPLOMACY_FACTOR);
}
sub suitable_route_creator
{
    my $self = shift;
    my $nation = $self->get_nation( shift );
    return 0 if($nation->production < ADDING_TRADEROUTE_COST);
    return 0 if($nation->internal_disorder_status eq 'Civil war');
    return 1;
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
        $self->broadcast_event($node1->name . " AND " . $node2->name . " REFUSED TO OPEN A TRADEROUTE", $node1->name, $node2->name);
        return 0;
    }
}



1;


