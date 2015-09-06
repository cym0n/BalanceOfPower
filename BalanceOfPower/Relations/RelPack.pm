package BalanceOfPower::Relations::RelPack;

use strict;
use v5.10;

use Moo;

has links => (
    is => 'rw',
    default => sub { [] }
);

sub all
{
    my $self = shift;
    return @{$self->links};
}

sub exists_link
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    foreach my $r (@{$self->links})
    {
        return $r if($r->is_between($node1, $node2));
    }
    return undef;
}

sub add_link
{
    my $self = shift;
    my $link = shift;
    if(! $self->exists_link($link))
    {
        push @{$self->links}, $link;
        return 1;
    }
    else
    {
        return 0;
    }
}
sub update_link
{
    my $self = shift;
    my $link = shift;
    $self->delete_link($link->node1, $link->node2);
    $self->add_link($link);
}
sub delete_link
{
    my $self = shift;
    my $n1 = shift;
    my $n2 = shift;
    @{$self->links} = grep { ! $_->involve($n1, $n2) } @{$self->links};
}
sub delete_link_for_node
{
    my $self = shift;
    my $n1 = shift;
    @{$self->links} = grep { ! $_->has_node($n1) } @{$self->links};
}
sub garbage_collector
{
    my $self = shift;
    my $query = shift;
    my @new = ();
    for(@{$self->links})
    {
        if(! $query->($_))
        {
            push @new, $_;
        }
    }
    @{$self->links} = @new;
}
sub links_for_node
{
    my $self = shift;
    my $node = shift;
    return $self->all() if(! $node);
    my @out = ();
    foreach my $r (@{$self->links})
    {
        if($r->has_node($node))
        {
            push @out, $r;
        }
    }
    return @out;
}
sub links_for_node1
{
    my $self = shift;
    my $node = shift;
    return $self->all() if(! $node);
    my @out = ();
    foreach my $r (@{$self->links})
    {
        if($r->bidirectional)
        {
            return $self->links_for_node($node);
        }
        if($r->node1 eq $node)
        {
            push @out, $r;
        }
    }
    return @out;
}
sub links_for_node2
{
    my $self = shift;
    my $node = shift;
    return $self->all() if(! $node);
    my @out = ();
    foreach my $r (@{$self->links})
    {
        if($r->bidirectional)
        {
            return $self->links_for_node($node);
        }
        if($r->node2 eq $node)
        {
            push @out, $r;
        }
    }
    return @out;
}
sub first_link_for_node
{
    my $self = shift;
    my $node = shift;
    foreach my $r (@{$self->links})
    {
        if($r->has_node($node))
        {
            return $r;
        }
    }
    return undef;
}
sub link_destinations_for_node
{
    my $self = shift;
    my $node = shift;
    my @nations = ();
    for(@{$self->links})
    {
        push @nations, $_->destination($node);
    }
    return @nations;
}

sub query
{
    my $self = shift;
    my $query = shift;
    my $nation = shift;
    my @out = ();
    for(@{$self->links})
    {
        if($query->($_))
        {
            if($nation)
            {
                if($_->has_node($nation))
                {
                    push @out, $_;
                }
            }
            else
            {
                push @out, $_;
            }
        }
    }
    return @out;
}

sub print_links
{
    my $self = shift;
    my $n = shift;
    my $out;
    foreach my $b (@{$self->links})
    {
        if($n)
        {
            if($b->has_node($n))
            {
                $out .= $b->print($n) . "\n";
            }
        }
        else
        {
            $out .= $b->print($n) . "\n";
        }
    }
    return $out;
}

1;
