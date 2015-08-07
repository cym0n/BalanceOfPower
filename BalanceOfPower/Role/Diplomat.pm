package BalanceOfPower::Role::Diplomat;

use strict;
use Moo::Role;

use BalanceOfPower::Utils qw(prev_year next_year random random10 get_year_turns);
use BalanceOfPower::Constants ':all';

has diplomatic_relations => (
    is => 'rw',
    default => sub { [] }
);

has situations => (
    is => 'rw',
    default => sub { {} }
);

requires 'register_event';

sub init_diplomacy
{
    my $self = shift;
    my @nations = @_;
    foreach my $n1 (@nations)
    {
        $self->situations->{$n1->name} = { status => 'free' };
        foreach my $n2 (@nations)
        {
            if($n1->name ne $n2->name && ! $self->diplomacy_exists($n1->name, $n2->name))
            {
                my $rel = new BalanceOfPower::Friendship( node1 => $n1->name,
                                                          node2 => $n2->name,
                                                          factor => random(0,100));
                push @{$self->diplomatic_relations}, $rel;
            }
        }
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
    if($self->situations->{$node}->{status} eq 'free')
    {
         return $node;
    }
    else
    {
        if($self->situations->{$node}->{status} eq 'conquered')
        {
            return $self->situations->{$node}->{by};
        }
        elsif($self->situations->{$node}->{status} eq 'under control')
        {
            return $self->situations->{$node}->{by};
        }
        else
        {
            return $node;
        }
    }
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
    else
    {
        my $r = $self->diplomacy_exists($real_node1, $real_node2);
        $factor = $r->factor;
    }
    return BalanceOfPower::Friendship->new(node1 => $node1, node2 => $node2, factor => $factor);
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
                $self->register_event("RELATION BETWEEN $node1 AND $node2 CHANGED FROM $present_status TO $actual_status", $node1, $node2);
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
sub free_nation
{
    my $self = shift;
    my $nation = shift;
    $self->situations->{$nation->name} = { status => 'free' };
    $nation->register_event("FREE!");
}
sub situation_clock
{
    my $self = shift;
    my $n = shift;
    my $situation = $self->situations->{$n->name};
    if(exists $situation->{clock})
    {
        $situation->{clock} = $situation->{clock} + 1;
        if($situation->{clock} == CONQUEST_CLOCK_LIMIT && $situation->{status} eq 'conquered')
        {
            $situation->{clock} = 0;
            $situation->{status} = 'under control';
            $n->register_event("UNDER CONTROL OF " . $situation->{'by'});
        }
    }
    $self->situations->{$n->name} = $situation;
}

sub is_under_influence
{
    my $self = shift;
    my $n = shift;
    if($self->situations->{$n}->{status} eq 'under influence')
    {  
        return $self->situations->{$n}->{by};
    }
    else
    {
        return undef;
    }
}
sub is_conquered
{
    my $self = shift;
    my $n = shift;
    if($self->situations->{$n}->{status} eq 'conquered')
    {  
        return $self->situations->{$n}->{by};
    }
    else
    {
        return undef;
    }
}
sub is_dominated
{
    my $self = shift;
    my $n = shift;
    return $self->is_under_influence($n)
        if($self->is_under_influence($n)); 
    return $self->is_conquered($n)
        if($self->is_conquered($n)); 
    return undef;
}
sub dominate
{
    my $self = shift;
    my $n = shift;
    if($self->situations->{$n}->{status} eq 'free')
    {
        my @under = ();
        foreach my $oth_n (keys %{$self->situations})
        {
            if($oth_n ne $n)
            {
                push @under, $oth_n
                    if($self->is_dominated($oth_n) eq $n);
            }
        }
        return @under;
    }
    else
    {
        return ();
    }

}





sub conquer
{
    my $self = shift;
    my $n1 = shift;
    my $n2 = shift;
    $self->situations->{$n2->name} = { status => 'conquered',
                                       by => $n1->name,
                                       clock => 0 };
    $n1->register_event("CONQUERED " . $n2->name);
    $n2->register_event("CONQUERED BY " . $n1->name);
}
sub under_influence
{
    my $self = shift;
    my $n1 = shift;
    my $n2 = shift;
    $self->situations->{$n2->name} = { status => 'under influence',
                                       by => $n1->name,
                                       clock => 0 };
    $n1->register_event("INFLUENCE ON " . $n2->name);
    $n2->register_event("UNDER INFLUENCE OF " . $n1->name);
}

1;
