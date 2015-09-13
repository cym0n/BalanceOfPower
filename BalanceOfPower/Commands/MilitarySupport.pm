package BalanceOfPower::Commands::MilitarySupport;

use Moo;

extends 'BalanceOfPower::Commands::TargetNation';

sub get_available_targets
{
    my $self = shift;
    return grep { ! $self->world->already_in_military_support($_) } $self->world->get_friends($self->world->player_nation);
}

1;
