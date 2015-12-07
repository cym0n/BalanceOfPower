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
has node1_starting_army => (
    is => 'rw',
    default => 0
);
has node2_starting_army => (
    is => 'rw',
    default => 0
);
has node2_faction => (
    is => 'rw',
    default => ""
);
has start_date => (
    is => 'ro'
);
has end_date => (
    is => 'rw'
);
has ending_line => (
    is => 'rw'
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
sub print_history
{
    my $self = shift;
    my $out = "";
    $out .= "### WAR " .  $self->war_id . "\n";
    $out .= $self->node1 . " => " . $self->node2 . "\n";
    $out .= "War started in " . $self->start_date . "\n";
    $out .= "Starting army for " . $self->node1 . ": " . $self->node1_starting_army . "\n";
    $out .= "Starting army for " . $self->node2 . ": " . $self->node2_starting_army . "\n";
    $out .= "War ended in " . $self->end_date . "\n";
    $out .= $self->ending_line . "\n";
    return $out;
}



1;
