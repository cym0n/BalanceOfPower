package BalanceOfPower::Role::Diplomat;

use strict;
use Moo::Role;
use List::Util qw(shuffle);


use BalanceOfPower::Utils qw(prev_year next_year random random10 get_year_turns);
use BalanceOfPower::Constants ':all';

use BalanceOfPower::Relations::Friendship;
use BalanceOfPower::Relations::Alliance;

has diplomatic_relations => (
    is => 'rw',
    default => sub { [] }
);
has alliances => (
    is => 'rw',
    default => sub { [] }
);

requires 'broadcast_event';

sub init_diplomacy
{
    my $self = shift;
    my @nations = @_;
    foreach my $n1 (@nations)
    {
        foreach my $n2 (@nations)
        {
            if($n1->name ne $n2->name && ! $self->diplomacy_exists($n1->name, $n2->name))
            {
                my $rel = BalanceOfPower::Relations::Friendship->new( node1 => $n1->name,
                                                           node2 => $n2->name,
                                                           factor => random(0,100));
                push @{$self->diplomatic_relations}, $rel;
            }
        }
    }
    for(my $i = 0; $i < STARTING_ALLIANCES; $i++)
    {
        @nations = shuffle @nations;
        $self->create_alliance($nations[0]->name, $nations[1]->name);
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
sub get_real_node
{
    my $self = shift;
    my $node = shift;
    my $domination = $self->is_under_influence($node);
    return $domination ? $domination->node1 : $node;
}
sub get_diplomacy_relation
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    my $real_node1 = $self->get_real_node($node1);
    my $real_node2 = $self->get_real_node($node2);
    my $factor;
    if($real_node1 eq $real_node2) 
    {
        $factor = 100;
    }
    elsif($self->exists_alliance($real_node1, $real_node2))
    {
        $factor = ALLIANCE_FRIENDSHIP_FACTOR;
    }
    else
    {
        my $r = $self->diplomacy_exists($real_node1, $real_node2);
        $factor = $r->factor;
    }
    return BalanceOfPower::Relations::Friendship->new(node1 => $node1, node2 => $node2, factor => $factor);
}


sub get_hates
{
    my $self = shift;
    my @out;
    foreach my $r (@{$self->diplomatic_relations})
    {
        my $real_r = $self->get_diplomacy_relation($r->node1, $r->node2);
        push @out, $real_r if $real_r->status eq 'HATE';
    }
    return @out;
}

sub change_diplomacy
{
    my $self = shift;
    my $node1 = $self->get_real_node( shift );
    my $node2 = $self->get_real_node( shift );
    my $dipl = shift;
    foreach my $r (@{$self->diplomatic_relations})
    {
        if($r->is_between($node1, $node2))
        {
            my $present_status = $r->status;
            $r->factor($r->factor + $dipl);
            $r->factor(0) if $r->factor < 0;
            $r->factor(100) if $r->factor > 100;
            my $actual_status = $r->status;
            if($present_status ne $actual_status)
            {
                $self->broadcast_event("RELATION BETWEEN $node1 AND $node2 CHANGED FROM $present_status TO $actual_status", $node1, $node2);
            }
        }
    }
}
sub diplomacy_status
{
    my $self = shift;
    my $n1 = shift;
    my $n2 = shift;
    my $r = $self->get_diplomacy_relation($n1, $n2);
    return $r->status;
}

sub diplomacy_for_node
{
    my $self = shift;
    my $node = shift;
    my %relations;
    my $real_node;
    foreach my $r (@{$self->diplomatic_relations})
    {
        if($r->has_node($node))
        {
            my $real_r = $self->get_diplomacy_relation($node, $r->destination($node));
            $relations{$r->destination($node)} = $real_r->factor;
        }
    }
    return %relations;;
}
sub print_diplomacy
{
    my $self = shift;
    my $n = shift;
    my $out;
    my @outnodes;
    foreach my $f (@{$self->diplomatic_relations})
    {
        if($f->has_node($n))
        {
            my $real_r = $self->get_diplomacy_relation($n, $f->destination($n));
            push @outnodes, $real_r;
        }
    }
    foreach my $rr (sort { $a->factor <=> $b->factor} @outnodes)
    {
        $out .= $rr->print($n) . "\n";
    }
    return $out;
}
sub coalition
{
    my $self = shift;
    my $n = shift;
    if(my $domination = $self->is_under_influence($n))
    {
        my $dominator = $domination->node1;
        my @allies = $self->has_influence($dominator);
        push @allies, $dominator;
        return @allies;
    }
    else
    {
        my @allies = $self->has_influence($n);
        push @allies, $n;
        return @allies;
    }
}
sub exists_alliance
{
   my $self = shift;
   my $n1 = shift;
   my $n2 = shift;
   foreach my $a (@{$self->alliances})
   {
        return $a
            if $a->involve($n1, $n2);
   }
   return undef;
}

sub create_alliance
{
    my $self = shift;
    my $n1 = shift;
    my $n2 = shift;
    if(! $self->exists_alliance($n1, $n2))
    {
        push @{$self->alliances}, BalanceOfPower::Relations::Alliance->new(node1 => $n1, node2 => $n2);
    }
    $self->broadcast_event("ALLIANCE BETWEEN $n1 AND $n2 CREATED", $n1, $n2);
}
sub delete_alliance
{
    my $self = shift;
    my $n1 = shift;
    my $n2 = shift;
    @{$self->alliances} = grep { ! $_->involve($n1, $n2) } @{$self->alliances};
    $self->broadcast_event("ALLIANCE BETWEEN $n1 AND $n2 ENDED", $n1, $n2);
}
sub delete_all_alliances
{
    my $self = shift;
    my $n1 = shift;
    foreach my $a (@{$self->alliances})
    {
        if($a->has_node($n1))
        {
            $self->delete_aliance($a->node1, $a->node2);
        }
    }
}
sub get_allies
{
    my $self  = shift;
    my $n1 = shift;
    my @allies = ();
    foreach my $a (@{$self->alliances})
    {
        if($a->has_node($n1))
        {
            push @allies, $a->destination($n1);
        }
    }
    return @allies;
}



1;
