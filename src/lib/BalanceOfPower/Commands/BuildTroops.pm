package BalanceOfPower::Commands::BuildTroops;

use Moo;

extends 'BalanceOfPower::Commands::NoArgs';

sub allowed
{
    my $self = shift;
    my $nation = $self->world->get_nation($self->actor);
    my $other_checks = $self->SUPER::allowed();
    if($other_checks)
    {
        my $export_cost = $nation->build_troops_cost();
        return $nation->production_for_export >= $export_cost;
    }
    else
    {
        return 0;
    }
}

1;
