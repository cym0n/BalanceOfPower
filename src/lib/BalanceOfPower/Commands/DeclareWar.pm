package BalanceOfPower::Commands::DeclareWar;

use v5.10;
use Moo;

use Array::Utils qw(intersect);

use BalanceOfPower::Constants ":all";
use BalanceOfPower::Utils qw( prev_turn );

extends 'BalanceOfPower::Commands::InMilitaryRange';


sub IA
{
    my $self = shift;
    my $actor = $self->get_nation();
    my @available = $self->get_available_targets();
    my @crises = $self->world->get_crises($actor->name);
    my @crisis_enemies;
    my %crisis_levels;
    foreach my $c (@crises)
    {
       push @crisis_enemies, $c->destination($actor->name); 
       $crisis_levels{$c->destination($actor->name)} = $c->get_crisis_level;
    }
    my @choose = $self->world->shuffle("Choosing someone to declare war to for ". $actor->name , intersect(@available, @crisis_enemies));
    for(@choose)
    {
        my $enemy = $self->world->get_nation($_);
        if($actor->good_prey($enemy, $self->world, $crisis_levels{$enemy->name}))
        {
            return "DECLARE WAR TO " . $enemy->name;
        }
    }
    return undef;
}

1;
