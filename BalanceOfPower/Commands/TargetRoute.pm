package BalanceOfPower::Commands::TargetRoute;

use Moo;

extends 'BalanceOfPower::Comands::TargetNation';

sub select_message
{
    my $self = shift;
    my $message = "";
    foreach my $tr ($self->world->routes_for_node($self->player_nation))
    {
        $message .= $tr->print($self->player_nation) . "\n";
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
    my $command = $self->SUPER::execute($query, $nation);
    $command .= "->" . $self->world->player_nation;
    return $command;
}

