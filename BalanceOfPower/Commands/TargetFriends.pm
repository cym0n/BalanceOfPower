package BalanceOfPower::Commands::TargetFriends;

use Moo;

extends 'BalanceOfPower::Commands::TargetNation';

sub get_available_targets
{
    my $self = shift;
    return $self->world->get_friends($self->world->player_nation);    
}

1;
