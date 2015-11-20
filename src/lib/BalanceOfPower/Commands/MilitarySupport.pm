package BalanceOfPower::Commands::MilitarySupport;

use Moo;

extends 'BalanceOfPower::Commands::TargetNation';

sub get_available_targets
{
    my $self = shift;
    my $player = $self->actor;
    return grep { $self->world->get_nation($_)->accept_military_support($player, $self->world) } $self->world->get_friends($player);
}

1;
