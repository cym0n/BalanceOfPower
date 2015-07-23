package BalanceOfPower::Role::Relation;

use strict;
use Moo::Role;

has node1 => (
    is => 'ro'
);
has node2 => (
    is => 'ro'
);
has bidirectional => (
    is => 'ro',
    default => 1,
);

sub has_node
{
    my $self = shift;
    my $node = shift;
    return $self->node1 eq $node || $self->node2 eq $node;
}
sub is_between
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    return ($self->node1 eq $node1 && $self->node2 eq $node2) ||
           ($self->node1 eq $node2 && $self->node2 eq $node1 && $self->bidirectional);
}
sub destination
{
    my $self = shift;
    my $node = shift;
    if($self->node1 eq $node)
    {
        return $self->node2;
    }
    elsif($self->node2 eq $node && $self->bidirectional)
    {
        return $self->node1;
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
    if($from && $from eq $self->node1)
    {
        return $from . " -> " . $self->node2;
    }
    elsif($from && $from eq $self->node2 )
    {
        if($self->bidirectional)
        {
            return $self->node2 . " -> " . $self->node1;
        }
        else
        {
            return $self->node1 . " -> " . $self->node2;
        }
    }
    else
    {
        if($self->bidirectional)
        {
            return $self->node1 . " <-> " . $self->node2;
        }
        else
        {
            return $self->node1 . " -> " . $self->node2;
        }
    }
}
1;
