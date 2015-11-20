package BalanceOfPower::Commands::NagTreaty;

use Moo;

extends 'BalanceOfPower::Commands::TargetNation';

sub get_available_targets
{
    my $self = shift;
    my @targets = $self->SUPER::get_available_targets();
    my $nation = $self->actor;
    @targets = grep {! $self->world->exists_treaty($nation, $_) } @targets;
    @targets = grep {! $self->world->diplomacy_status($nation, $_) ne 'HATE' } @targets;
    return @targets;
}

1;
