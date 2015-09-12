package BalanceOfPower::Role::Diplomat;

use strict;
use v5.10;
use Moo::Role;
use List::Util qw(shuffle);
use Data::Dumper;


use BalanceOfPower::Utils qw( random );
use BalanceOfPower::Constants ':all';

use BalanceOfPower::Relations::Friendship;
use BalanceOfPower::Relations::Alliance;
use BalanceOfPower::Relations::RelPack;

has diplomatic_relations => (
    is => 'ro',
    default => sub { BalanceOfPower::Relations::RelPack->new() },
    handles => { add_diplomacy => 'add_link',
                 diplomacy_exists => 'exists_link',
                 update_diplomacy => 'update_link' }
);
has alliances => (
    is => 'ro',
    default => sub { BalanceOfPower::Relations::RelPack->new() },
    handles => { add_alliance => 'add_link',
                 print_allies => 'print_links',
                 exists_alliance => 'exists_link',
                 get_allies => 'links_for_node' }
);

requires 'broadcast_event';
requires 'is_under_influence';
requires 'has_influence';

sub init_diplomacy
{
    my $self = shift;
    my @nations = @{$self->nation_names};
    foreach my $n1 (@nations)
    {
        foreach my $n2 (@nations)
        {
            if($n1 ne $n2 && ! $self->diplomacy_exists($n1, $n2))
            {
                my $minimum_friendship = 0;
                if($self->exists_alliance($n1, $n2))
                {
                    $minimum_friendship = LOVE_LIMIT + 1;
                }
                  
                my $rel = BalanceOfPower::Relations::Friendship->new( node1 => $n1,
                                                           node2 => $n2,
                                                           factor => random($minimum_friendship ,100));
                $self->add_diplomacy($rel);
            }
        }
    }
}
sub init_random_alliances
{
    my $self = shift;
    my @nations = @{$self->nation_names};
    for(my $i = 0; $i < STARTING_ALLIANCES; $i++)
    {
        #@nations = shuffle @nations;
        my $n1 = $nations[random(0, $#nations)];
        my $n2 = $nations[random(0, $#nations)];
        if($n1 ne $n2)
        {
            my $all = BalanceOfPower::Relations::Alliance->new(node1 => $n1, node2 => $n2);
            $self->add_alliance($all);
            $self->broadcast_event("ALLIANCE BETWEEN $n1 AND $n2 CREATED", $n1, $n2);
        }
    }
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
    return $self->diplomatic_relations->query( sub { my $rel = shift; return $rel->status eq 'HATE' });
}
sub get_friends
{
    my $self = shift;
    my $nation = shift;
    my @friendships = $self->diplomatic_relations->query( sub { my $rel = shift; return $rel->status eq 'FRIENDSHIP' }, $nation);
    my @out = ();
    for(@friendships)
    {
        push @out, $_->destination($nation);
    }
    return @out;
}

sub change_diplomacy
{
    my $self = shift;
    my $node1 = $self->get_real_node( shift );
    my $node2 = $self->get_real_node( shift );
    my $dipl = shift;
    my $r = $self->diplomacy_exists($node1, $node2);
    return if(!$r ); #Should never happen
    my $present_status = $r->status;
    $r->change_factor($dipl);
    my $actual_status = $r->status;
    if($present_status ne $actual_status)
    {
        $self->broadcast_event("RELATION BETWEEN $node1 AND $node2 CHANGED FROM $present_status TO $actual_status", $node1, $node2);
    }
}
sub add_friendship
{
    my $self = shift;
    my $node1 = $self->get_real_node( shift );
    my $node2 = $self->get_real_node( shift );
    my $delta = shift;
    my $r = $self->diplomacy_exists($node1, $node2);
    return if(!$r ); #Should never happen
    $self->change_diplomacy($node1, $node2, $r->factor + $delta);
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
    foreach my $n (@{$self->nation_names})
    {
        if($n ne $node)
        {
            my $real_r = $self->get_diplomacy_relation($node, $n);
            $relations{$n} = $real_r->factor;
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
    foreach my $f ($self->diplomatic_relations->all())
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



1;
