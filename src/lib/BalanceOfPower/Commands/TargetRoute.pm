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

sub execute
{
    my $self = shift;
    my $query = shift;
    my $nation = shift;
    my $result = $self->SUPER::execute($query, $nation);
    if($result->{status} == 1)
    {
        my $command = $result->{command};
        $command .= "->" . $self->world->player_nation;
        return { status => 1, command => $command };
    }
    else
    {
        return $result;
    }
}

1;

