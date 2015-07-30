package BalanceOfPower::Role::Diplomat;

use strict;
use Moo::Role;

has diplomatic_relations => (
    is => 'rw',
    default => sub { [] }
);

requires 'register_event';

sub get_hates
{
    my $self = shift;
    my @out = grep { $_->status eq 'HATE' } @{$self->diplomatic_relations};

}

sub change_diplomacy
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    my $dipl = shift;
    foreach my $r (@{$self->diplomatic_relations})
    {
        if($r->is_between($node1, $node2))
        {
            if(! $r->leader)
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
}
sub diplomacy_status
{
    my $self = shift;
    my $n1 = shift;
    my $n2 = shift;
    foreach my $r (@{$self->diplomatic_relations})
    {
        if($r->is_between($n1, $n2))
        {
            return $r->status;
        }
    }
}
sub diplomacy_for_node
{
    my $self = shift;
    my $node = shift;
    my %relations;
    foreach my $r (@{$self->diplomatic_relations})
    {
        if($r->has_node($node))
        {
             $relations{$r->destination($node)} = $r->factor;
        }
    }
    return %relations;;
}
sub print_diplomacy
{
    my $self = shift;
    my $n = shift;
    my $out;
    foreach my $f (sort {$a->factor <=> $b->factor} @{$self->diplomatic_relations})
    {
        if($f->has_node($n))
        {
            $out .= $f->print($n) . "\n";
        }
    }
    return $out;
}

sub diplomacy_exists
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    foreach my $r (@{$self->diplomatic_relations})
    {
        return 1 if($r->is_between($node1, $node2));
    }
    return 0;
}

sub free_nation
{
    my $self = shift;
    my $nation = shift;
    $nation->situation({ status => 'free' });
    foreach my $f (@{$self->diplomatic_relations})
    {
        if($f->has_node($nation->name))
        {
            if($f->leader && $f->leader ne $nation->name)
            {
                $f->leader(undef);
            }
        }
    }
    $nation->register_event("NATION IS FREE!");
}

1;
