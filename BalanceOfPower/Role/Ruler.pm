package BalanceOfPower::Role::Ruler;

use strict;
use Moo::Role;

use BalanceOfPower::Constants ':all';

use BalanceOfPower::Relations::Influence;

requires 'broadcast_event';
requires 'get_nation';

has influences => (
    is => 'ro',
    default => sub { BalanceOfPower::Relations::RelPack->new() },
    handles => { reset_influences => 'delete_link_for_node',
                 add_influence => 'add_link' }
);
sub influences_garbage_collector
{
    my $self = shift;
    $self->influences->garbage_collector(sub { my $rel = shift; return $rel->status == -1 });
}
sub is_under_influence
{
    my $self = shift;
    my $nation = shift;
    my @rels = $self->influences->query(
        sub {
            my $rel = shift;
            return 0 if($rel->node2 ne $nation);
            return $rel->actual_influence()
        }, $nation);
    if(@rels > 0)
    {
        return $rels[0]->start($nation);
    }
    else
    {
        return undef;
    }
}
sub print_nation_situation
{
    my $self = shift;
    my $nation = shift;
    my $domination = $self->is_under_influence($nation);
    return "$nation is under control of $domination" if $domination;
    my @influence = $self->has_influence($nation);
    if(@influence > 0)
    {
        my $out = "$nation has influence on";
        for(@influence)
        {
            my $i = shift @influence;
            $out .= " " . $i;
            $out .= "," if(@influence > 0);
        }
        return $out;
    }
    else
    {
        return "$nation is free";
    }

}
sub has_influence
{
    my $self = shift;
    my $nation = shift;
    my @influences = $self->influences->query(
                        sub {
                            my $rel = shift;
                            return 0 if($rel->node1 ne $nation);
                            return $rel->actual_influence()
                        }, $nation);
    my @out = ();
    for(@influences)
    {
        push @out, $_->destination($nation);
    }
    return @out;
}
sub occupy
{
    my $self = shift;
    my $nation = shift;
    my $occupiers = shift;
    my $leader = shift;
    my $internal_disorder = shift || 0;
    $self->get_nation($nation)->occupation($self);
    foreach my $c (@{$occupiers})
    {
        if($c eq $leader)
        {
            $self->add_influence(BalanceOfPower::Relations::Influence->new( node1 => $c,
                                                                       node2 => $nation,
                                                                       status => 0,
                                                                       next => $internal_disorder ? 2 : 1,
                                                                       clock => 0 ));
        }
        else
        {
            $self->add_influence(BalanceOfPower::Relations::Influence->new( node1 => $c,
                                                                       node2 => $nation,
                                                                       status => 0,
                                                                       clock => 0 ));
        }
        $self->broadcast_event("$c OCCUPIES $nation", $c, $nation);
    }
}
sub situation_clock
{
    my $self = shift;
    foreach my $i ($self->influences->all())
    {
        my $old_status = $i->status_label;
        my $new_status = $i->click();    
        if($new_status && $old_status ne $new_status)
        {
            if($new_status eq 'dominate')
            {
                $self->broadcast_event($i->node1 . " DOMINATES " . $i->node2, $i->node1, $i->node2);
            }
            elsif($new_status eq 'control')
            {
                $self->broadcast_event($i->node1 . " CONTROLS " . $i->node2, $i->node1, $i->node2);
            }
        }
    }
    $self->influences_garbage_collector();
}

1;
