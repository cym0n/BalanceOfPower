package BalanceOfPower::Player::Role::Traveler;

use strict;
use v5.10;
use Moo::Role;

use BalanceOfPower::Constants ':all';



has position => (
    is => 'rw',
);

has movements => (
    is => 'rw',
);

sub make_travel_plan
{
    my $self = shift;
    my $world = shift;
    my @already = ();
    my %plan;
    $plan{'ground'} = {};
    $plan{'air'} = {};
    my @for_commerce = $world->route_destinations_for_node($self->position);
    
    my @at_borders = $world->near_nations($self->position, 1);
    foreach my $n(@for_commerce)
    {
        if(! grep { $_ eq $n } @already)
        {
            my $youcan = 'OK';
            $youcan = 'KO' if($world->war_busy($self->position) || $world->war_busy($n));
            $plan{'air'}->{$n}->{status} = $youcan;
            my $cost = $world->distance($self->position, $n) * AIR_TRAVEL_COST_FOR_DISTANCE;
            $cost = AIR_TRAVEL_CAP_COST if $cost > AIR_TRAVEL_CAP_COST;
            $plan{'air'}->{$n}->{cost} = $cost if($youcan eq 'OK');
            push @already, $n if $youcan eq 'OK';
        }
    }
    foreach my $n(@at_borders)
    {
        if(! grep { $_ eq $n } @already)
        {
            $plan{'ground'}->{$n}->{status} = 'OK';
            $plan{'ground'}->{$n}->{cost} = GROUND_TRAVEL_COST;
            push @already, $n;
        }
    }
    return %plan;
}

sub print_travel_plan
{
    my $self = shift;
    my $world = shift;
    my $mode = shift || 'print';
    my %plan = $self->make_travel_plan($world);
    return BalanceOfPower::Printer::print($mode, $self, 'print_travel_plan', 
                                          { plan => \%plan } );
    
}

sub refill_movements
{
    my $self = shift;
    $self->movements(PLAYER_MOVEMENTS);
}
sub go
{
    my $self = shift;
    my $world = shift;
    my $destination = shift;
    my %plan = $self->make_travel_plan($world);
    foreach my $way ('air', 'ground')
    {
        if(my $route = $plan{$way}->{$destination})
        {
            if($route->{status} eq 'KO')
            {
                return -1;
            }        
            elsif($route->{cost} > $self->movements)
            {
                return -2;
            }
            $self->movements($self->movements - $route->{cost});
            $self->position($destination);   
            return (1, { destination => $destination, way => $way, cost => $route->{cost} });     
        }
    }
    return -3;
}
1;
