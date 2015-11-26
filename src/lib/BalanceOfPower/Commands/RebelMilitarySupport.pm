package BalanceOfPower::Commands::RebelMilitarySupport;

use Moo;

extends 'BalanceOfPower::Commands::TargetNation';

sub get_available_targets
{
    my $self = shift;
    my $player = $self->actor;
    return grep { $self->world->at_civil_war($_) && ! $self->world->rebel_supported($_)  }  @{$self->world->nation_names};
}

sub IA
{
    my $self = shift;
    my $player = $self->actor;
    my @enemies = $self->world->shuffle("Choosing enemy for rebel support for " . $self->actor, $self->world->get_hates($self->actor)); 
    foreach my $e (@enemies)
    {
        my $target = $e->destination($self->actor);
        if($self->good_target($target))
        {
            return "REBEL MILITARY SUPPORT " . $e->destination($self->actor);
        }
    }
}

1;
