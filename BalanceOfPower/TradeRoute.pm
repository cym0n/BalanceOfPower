package BalanceOfPower::TradeRoute;

use strict;
use v5.10;

use Moo;

has factor1 => (
    is => 'ro'
);
has factor2 => (
    is => 'ro'
);

with 'BalanceOfPower::Role::Relation';

sub factor_for_node
{
    my $self = shift;
    my $node = shift;
    if ($self->node1 eq $node)
    {
        return $self->factor1;
    }
    elsif ($self->node2 eq $node)
    {
        return $self->factor2;
    }
    else
    {
        return undef;
    }
}
sub print 
{
    my $self = shift;
    my $from = shift;
    if($from eq $self->node1)
    {
        say $from . " -x" . $self->factor1 . "-> " . $self->node2;
    }
    elsif($from eq $self->node2)
    {
        say $from . " -x" . $self->factor2 . "-> " . $self->node1;
    }
}




1;


