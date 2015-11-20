package BalanceOfPower::Commands::RecallMilitarySupport;

use Moo;

extends 'BalanceOfPower::Commands::TargetNation';

sub get_available_targets
{
    my $self = shift;
    my @supported = $self->world->supporter($self->world->actor);
    my @out = ();
    for(@supported)
    {
        push @out, $_->destination($self->actor);
    }
    return @out;
}

1;
