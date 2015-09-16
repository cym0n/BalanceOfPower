package BalanceOfPower::Commands::RecallMilitarySupport;

use Moo;

extends 'BalanceOfPower::Commands::TargetNation';

sub get_available_targets
{
    my $self = shift;
    my @supported = $self->world->supporter($self->world->get_player_nation()->name);
    my @out = ();
    for(@supported)
    {
        push @out, $_->destination($self->world->player_nation);
    }
    return @out;
}

1;
