package BalanceOfPower::Relations::War;

use strict;
use v5.10;

use Moo;
use BalanceOfPower::Utils qw( from_to_turns );
use Term::ANSIColor;

with 'BalanceOfPower::Relations::Role::Relation';
with 'BalanceOfPower::Role::Reporter';

has attack_leader => (
    is => 'rw',
    default => ""
);
has war_id => (
    is => 'rw',
    default => ""
);
has name => (
    is => 'rw',
    default => "WAR"
);
has node1_faction => (
    is => 'rw',
    default => ""
);
has node2_faction => (
    is => 'rw',
    default => ""
);
has start_date => (
    is => 'ro',
    default => ""
);
has end_date => (
    is => 'rw',
    default => ""
);
has current_year => (
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
sub print_history
{
    my $self = shift;
    my $out = "";
    #$out .= "### WAR " .  $self->war_id . "\n";
    $out .= $self->node1;
    if($self->attack_leader && $self->attack_leader ne $self->node1)
    {
        $out .= " (" . $self->attack_leader . ")";
    }
    $out .= " => " . $self->node2 . "\n";
    $out .= "*** War started in " . $self->start_date . " ***\n";
    $out .= $self->print_turn_events_notitle("START");
    for(from_to_turns($self->start_date, $self->end_date))
    {
        my $events = $self->print_turn_events_inline_year($_);
        if($events)
        {
            $out .= $events;
        }
    }
    $out .= "*** War ended in " . $self->end_date . " ***\n";
    return $out;
}
sub dump
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
    print {$io} $indent . join(";", $self->node1, $self->node2, $self->attack_leader,
                                    $self->war_id, $self->name, $self->node1_faction, $self->node2_faction, 
                                    $self->start_date, $self->end_date, $self->current_year ). "\n";
    if($self->events)
    {    
        $self->dump_events($io, $indent . " ");
    }
}



1;
