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
    my $node1 = $self->node1;
    my $node2 = $self->node2;
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
