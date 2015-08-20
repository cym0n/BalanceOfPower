package BalanceOfPower::Relations::Influence;

use strict;
use v5.10;

use Moo;
use BalanceOfPower::Utils qw(prev_year next_year random random10 get_year_turns);
use BalanceOfPower::Constants ':all';


with 'BalanceOfPower::Relations::Role::Relation';

# Status:
#   0: occupy
#   1: dominate
#   2: control

has status => (
    is => 'rw',
    default => -1
);
has next => (
    is => 'rw',
    default => -1
);
has clock => (
    is => 'rw',
    default => 0
);
sub bidirectional
{
    return 0;
}
sub status_label
{
    my $self = shift;
    if($self->status == 0)
    {
        return 'occupy';
    }
    elsif($self->status == 1)
    {
        return 'dominate';
    }
    elsif($self->status == 2)
    {
        return 'control';
    }
    else
    {
        return undef;
    }
}
sub get_loot_quote
{
    my $self = shift;
    if($self->status == 0)
    {
        return OCCUPATION_LOOT_BY_TYPE
    }
    elsif($self->status == 1)
    {
        return DOMINATION_LOOT_BY_TYPE;
    }
    elsif($self->status == 2)
    {
        return CONTROL_LOOT_BY_TYPE;
    }
    else
    {
        return undef;
    }
}
sub click
{
    my $self = shift;
    $self->clock($self->clock + 1);
    if($self->status == 0 && $self->clock >= OCCUPATION_CLOCK_LIMIT)
    {
        return $self->change_to_next();
    }
    elsif($self->status == 1 && $self->clock >= DOMINATION_CLOCK_LIMIT)
    {
        return $self->change_to_next();
    }
    else
    {
        return $self->status;
    }
}
sub change_to_next
{
    my $self = shift;
    $self->status($self->next);
    $self->clock(0);
    return $self->status_label;
}
sub print
{
    my $self = shift;
    return $self->node1 . " " . $self->status_label . " " . $self->node2;
}



1;
