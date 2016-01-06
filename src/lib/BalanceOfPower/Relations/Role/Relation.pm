package BalanceOfPower::Relations::Role::Relation;

use strict;
use Moo::Role;

has node1 => (
    is => 'ro'
);
has node2 => (
    is => 'ro'
);

sub bidirectional
{
    return 1;
}

sub has_node
{
    my $self = shift;
    my $node = shift;
    return $self->node1 eq $node || $self->node2 eq $node;
}
sub is_between
{
    my $self = shift;
    my $node1 = shift || "";
    my $node2 = shift || "";

    return ($self->node1 eq $node1 && $self->node2 eq $node2) ||
           ($self->node1 eq $node2 && $self->node2 eq $node1 && $self->bidirectional);
}
sub involve
{
    my $self = shift;
    my $node1 = shift || "";
    my $node2 = shift || "";

    return ($self->node1 eq $node1 && $self->node2 eq $node2) ||
           ($self->node1 eq $node2 && $self->node2 eq $node1);
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
sub start
{
    my $self = shift;
    my $node = shift;
    if($self->node2 eq $node)
    {
        return $self->node1;
    }
    elsif($self->node1 eq $node && $self->bidirectional)
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
sub dump
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
    print {$io} $indent . $self->node1 . ";" . $self->node2 . "\n";
}
sub load
{
    my $self = shift;
    my $data = shift;
    $data =~ s/^\s+//;
    chomp $data;
    my ($node1, $node2) = split ";", $data;
    return $self->new(node1 => $node1, node2 => $node2);
}
1;
