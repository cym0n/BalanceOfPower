package BalanceOfPower::Commands::TargetRoute;

use Moo;
use Data::Dumper;

extends 'BalanceOfPower::Commands::TargetNation';

sub select_message
{
    my $self = shift;
    my $message = "";
    foreach my $tr ($self->world->routes_for_node($self->world->player_nation))
    {
        $message .= $tr->print($self->world->player_nation) . "\n";
    }
    $message .= "\n";
    $message .= "Select traderoute:\n";
    return $message;
}

sub get_available_targets
{
    my $self = shift;
    return $self->world->route_destinations_for_node($self->world->player_nation);    
}



1;

