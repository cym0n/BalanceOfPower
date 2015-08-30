package BalanceOfPower::Relations::War;

use strict;
use v5.10;

use Moo;
use Term::ANSIColor;

with 'BalanceOfPower::Relations::Role::Relation';

has attack_leader => (
    is => 'rw',
    default => ""
);
has war_id => (
    is => 'rw',
    default => ""
);
has node1_faction => (
    is => 'rw',
    default => ""
);
has node2_faction => (
    is => 'rw',
    default => ""
);
sub bidirectional
{
    return 0;
}
sub print 
{
    my $self = shift;
    my $army_node1 = shift;
    my $army_node2 = shift;
    my $army_node1_label = $army_node1 ? "[".$army_node1."] " : "";
    my $army_node2_label = $army_node2 ? " [".$army_node2."]" : "";
    my $node1 = $army_node1_label . $self->node1;
    my $node2 = $self->node2 . $army_node2_label;
    if($self->node1_faction == 0)
    {
        $node1 = color("bold") . $node1 . color("reset");
    }
    else
    {
        $node2 = color("bold") . $node2 . color("reset");
    }
    return  $node1 . " -> " . $node2;
}



1;
