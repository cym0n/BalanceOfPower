package BalanceOfPower::Relations::Friendship;

use strict;
use v5.10;

use Moo;
use BalanceOfPower::Constants ':all';
use Term::ANSIColor;

has factor => (
    is => 'rw'
);
with 'BalanceOfPower::Relations::Role::Relation';

sub status
{
    my $self = shift;
    if($self->factor == ALLIANCE_FRIENDSHIP_FACTOR)
    {
        return 'ALLIANCE';
    }
    if($self->factor <= HATE_LIMIT)
    {
        return 'HATE';
    }
    elsif($self->factor >= LOVE_LIMIT)
    {
        return 'FRIENDSHIP';
    }
    else
    {
        return 'NEUTRAL';
    }
}

sub status_color
{
    my $self = shift;
    if($self->status eq 'ALLIANCE')
    {
        return color("cyan bold");
    }
    if($self->status eq 'HATE')
    {
        return color("red bold");
    }
    elsif($self->status eq 'FRIENDSHIP')
    {
        return color("green bold");
    }
    else
    {
        return "";
    }
}


sub print 
{
    my $self = shift;
    my $from = shift;
    if($from)
    {
        if($from eq $self->node1)
        {
            return $self->status_color . $from . " <--> " . $self->node2 . " [" . $self->factor . " " . $self->status . "]" . color("reset");
        }
        elsif($from eq $self->node2)
        {
            return $self->status_color . $from . " <--> " . $self->node1 . " [" . $self->status . "]" . color("reset");
        }
    }
    else
    {
        return $self->status_color . $self->node1 . " <--> " . $self->node2 . " [" . $self->status . "]" . color("reset");
    }

}

sub change_factor
{
    my $self = shift;
    my $delta = shift;
    my $new_factor = $self->factor + $delta;
    $new_factor = $new_factor < 0 ? 0 : $new_factor > 100 ? 100 : $new_factor;
    $self->factor($new_factor);
}

1;
