package BalanceOfPower::Role::Merchant;

use strict;
use Moo::Role;

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw(prev_year next_year random random10 get_year_turns);

requires 'get_nation';
requires 'register_event';
requires 'change_diplomacy';
requires 'diplomacy_status';

has trade_routes => (
    is => 'rw',
    default => sub { [] }
);

sub generate_traderoute
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
        $self->change_diplomacy($node1, $node2, TRADEROUTE_DIPLOMACY_FACTOR);
        my $event = "TRADEROUTE ADDED: $node1<->$node2";
        $self->register_event($event, $node1, $node2);
    }
               
}
sub delete_route
{
    my $self = shift;
    my $node1 = shift;;
    my $node2 = shift;
    return if ! $self->route_exists($node1, $node2);
    my $n1 = $self->get_nation($node1);
    my $n2 = $self->get_nation($node2);
    
    @{$self->trade_routes} = grep { ! $_->is_between($node1, $node2) } @{$self->trade_routes};
    my $event = "TRADEROUTE DELETED: $node1<->$node2";
    $self->register_event($event, $node1, $node2);
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
        $self->register_event($node1->name . " AND " . $node2->name . " REFUSED TO OPEN A TRADEROUTE", $node1->name, $node2->name);
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

1;


