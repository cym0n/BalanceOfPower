package BalanceOfPower::Commands::DeleteRoute;

use Moo;

extends 'BalanceOfPower::Commands::TargetRoute';

sub get_available_targets
{
    my $self = shift;
    my @targets = $self->SUPER::get_available_targets();
    my $nation = $self->actor;
    @targets = grep {! $self->world->exists_treaty_by_type($nation, $_, 'commercial') } @targets;
    return @targets;
}

sub execute
{
    my $self = shift;
    my $query = shift;
    my $nation = shift;
    my $result = $self->SUPER::execute($query, $nation);
    if($result->{status} == 1)
    {
        my $command = $result->{command};
        $command .= "->" . $self->actor;
        return { status => 1, command => $command };
    }
    else
    {
        return $result;
    }
}
 
1;
