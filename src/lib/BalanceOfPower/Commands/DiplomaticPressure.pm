package BalanceOfPower::Commands::DiplomaticPressure;

use Moo;

extends 'BalanceOfPower::Commands::TargetNation';

sub IA
{
    my $self = shift;
    my $actor = $self->get_nation();
    my @hates = $self->world->shuffle("Choosing target for diplomatic pressure for ". $self->actor, $self->world->get_nations_with_status($self->actor, ['HATE']));
    return "DIPLOMATIC PRESSURE ON " . $hates[0];
}
1;
