package BalanceOfPower::Relations::Friendship;

use strict;
use v5.10;

use Moo;
use BalanceOfPower::Constants ':all';

has factor => (
    is => 'rw'
);
with 'BalanceOfPower::Relations::Role::Relation';

sub status
{
    my $self = shift;
    if($self->factor == ALLIANCE_FRIENDSHIP_FACTOR)
    {
        return 'ALLIANCE';
    }
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
    if($from)
    {
        if($from eq $self->node1)
        {
            return $from . " <-" . $self->factor . "-> " . $self->node2 . " [" . $self->status . "]";
        }
        elsif($from eq $self->node2)
        {
            return $from . " <-" . $self->factor . "-> " . $self->node1 . " [" . $self->status . "]";
        }
    }
    else
    {
        return $self->node1 . " <-" . $self->factor . "-> " . $self->node2 . " [" . $self->status . "]";
    }

}
sub diplomacy_exists
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    foreach my $r (@{$self->diplomatic_relations})
    {
        return $r if($r->is_between($node1, $node2));
    }
    return undef;
}
1;
