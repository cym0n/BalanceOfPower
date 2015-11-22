package BalanceOfPower::Commands::RecallMilitarySupport;

use Moo;

use BalanceOfPower::Constants ':all';

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

sub IA
{
    my $self = shift;
    my $actor = $self->get_nation();
    if($actor->army <= ARMY_TO_RECALL_SUPPORT)
    {
        my @supports = $self->world->supporter($actor->name);
        if(@supports > 0)
        {
            @supports = $self->world->shuffle("Choosing support to recall", @supports);
            return "RECALL MILITARY SUPPORT " . $supports[0]->destination($actor->name);
        }
    }
    return undef;
}

1;
