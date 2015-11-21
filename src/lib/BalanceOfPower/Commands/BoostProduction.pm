package BalanceOfPower::Commands::BoostProduction;

use Moo;

use BalanceOfPower::Constants ":all";

extends 'BalanceOfPower::Commands::NoArgs';

sub IA
{
    my $self = shift;
    my $nation = $self->get_nation();
    if($nation->production < EMERGENCY_PRODUCTION_LIMIT)
    {
        return "BOOST PRODUCTION"
    }
    else
    {
        return undef;
    }
}

1;
