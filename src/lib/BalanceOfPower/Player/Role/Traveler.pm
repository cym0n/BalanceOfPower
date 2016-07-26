package BalanceOfPower::Player::Role::Traveler;

use strict;
use v5.10;
use Moo::Role;

use BalanceOfPower::Constants ':all';



has position => (
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
            $plan{'air'}->{$n} = $youcan;
            push @already, $n if $youcan eq 'OK';
        }
    }
    foreach my $n(@at_borders)
    {
        if(! grep { $_ eq $n } @already)
        {
            $plan{'ground'}->{$n} = 'OK';
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
1;
