package BalanceOfPower::Relations::TradeRoute;

use strict;
use v5.10;

use Moo;

has factor1 => (
    is => 'ro'
);
has factor2 => (
    is => 'ro'
);

with 'BalanceOfPower::Relations::Role::Relation';

has '+rel_type' => (
    is => 'ro',
    default => 'traderoute'
);



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
        return $from . " -[x" . $self->factor1 . "]-> " . $self->node2;
    }
    elsif($from eq $self->node2)
    {
        return $from . " -[x" . $self->factor2 . "]-> " . $self->node1;
    }
}
sub dump
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
    print {$io} $indent . join(";", $self->node1, $self->node2, $self->factor1, $self->factor2) . "\n";
}
sub to_mongo
{
    my $self = shift;
    return { rel_type => $self->rel_type,
             node1 => $self->node1,
             node2 => $self->node2,
             factor1 => $self->factor1,
             factor2 => $self->factor2,
    }
}
sub load
{
    my $self = shift;
    my $data = shift;
    $data =~ s/^\s+//;
    chomp $data;
    my ($node1, $node2, $factor1, $factor2) = split ";", $data;
    return $self->new(node1 => $node1, node2 => $node2, factor1 => $factor1, factor2 => $factor2);
}






1;


