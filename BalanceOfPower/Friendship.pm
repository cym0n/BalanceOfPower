package BalanceOfPower::Friendship;

use strict;
use v5.10;

use Moo;
use BalanceOfPower::Constants ':all';

has factor => (
    is => 'rw'
);

with 'BalanceOfPower::Role::Relation';

sub status
{
    my $self = shift;
    if($self->factor < HATE_LIMIT)
    {
        return 'HATE';
    }
    elsif($self->factor > LOVE_LIMIT)
    {
        return 'FRIENDSHIP';
    }
    else
    {
        return 'NEUTRAL';
    }
}

sub print 
{
    my $self = shift;
    my $from = shift;
    if($from eq $self->node1)
    {
        return $from . " <-" . $self->factor . "-> " . $self->node2 . " [" . $self->status . "]";
    }
    elsif($from eq $self->node2)
    {
        return $from . " <-" . $self->factor . "-> " . $self->node1 . " [" . $self->status . "]";
    }
}
1;
