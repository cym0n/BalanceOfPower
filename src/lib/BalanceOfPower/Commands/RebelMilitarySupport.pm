package BalanceOfPower::Commands::RebelMilitarySupport;

use Moo;

extends 'BalanceOfPower::Commands::TargetNation';

sub get_available_targets
{
    my $self = shift;
    my $player = $self->actor;
    return grep { $self->world->at_civil_war($_)  }  @{$self->world->nations};
}

sub IA
{
    my $self = shift;
    my $player = $self->actor;
    my @enemies = $self->world->shuffle("Choosing enemy for rebel support for " . $self->actor, $self->world->get_hates($self->actor)); 
    foreach my $e (@enemies)
    {
        if($self->world->at_civil_war($e->destination($self->actor)))
        {
            return "REBEL MILITARY SUPPORT " . $e->destination($self->actor);
        }
    }
}

1;
