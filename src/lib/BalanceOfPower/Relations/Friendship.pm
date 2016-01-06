package BalanceOfPower::Relations::Friendship;

use strict;
use v5.10;

use Moo;
use BalanceOfPower::Constants ':all';
use Term::ANSIColor;

has factor => (
    is => 'rw'
);
has crisis_level => (
    is => 'rw',
    default => 0
);
with 'BalanceOfPower::Relations::Role::Relation';

sub get_crisis_level
{
    my $self = shift;
    if($self->factor > PERMANENT_CRISIS_HATE_LIMIT)
    {
        return $self->crisis_level;
    }
    else
    {
        if($self->crisis_level < CRISIS_MAX_FACTOR)
        {
            return $self->crisis_level + 1;
        }
        else
        {
            return $self->crisis_level;
        }
    }
}
sub status
{
    my $self = shift;
    if($self->factor == ALLIANCE_FRIENDSHIP_FACTOR)
    {
        return 'ALLIANCE';
    }
    elsif($self->factor == DOMINION_DIPLOMACY)
    {
        return 'INFLUENCE PRESENT';
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
    if($self->status eq 'ALLIANCE' || $self->status eq 'INFLUENCE PRESENT')
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
    my $second_node;
    my $out;
    if($from)
    {
        if($from eq $self->node1)
        {
            $second_node = $self->node2;
        }
        elsif($from eq $self->node2)
        {
            $second_node = $self->node1;
        }
    }
    else
    {
        $from = $self->node1;
        $second_node = $self->node2;
    }
    $out = $self->status_color . $from . " <--> " . $second_node . " [" . $self->factor . " " . $self->status . "]";
    if($self->get_crisis_level > 0)
    {
        $out .= " " . $self->print_crisis_bar();
    }
    $out .= color("reset");
    return $out;
}
sub print_status
{
    my $self = shift;
    return $self->status_color . $self->status . color("reset");
}
sub print_crisis
{
    my $self = shift;
    my $color = shift;
    $color = 1 if(! defined $color);
    if($self->get_crisis_level > 0)
    {
        my $out = $self->node1 . " <-> " . $self->node2;
        if($color)
        {
            return $out . " " . $self->print_crisis_bar();
        }
        else
        {
            return $out . " " . $self->print_grey_crisis_bar();
        }
    }
    else
    {
        return "";
    }
}
sub print_grey_crisis_bar
{
    my $self = shift;
    my $out = "";
    if($self->get_crisis_level > 0)
    {
        $out .= "[";
        for(my $i = 0; $i < CRISIS_MAX_FACTOR; $i++)
        {
            if($i < $self->get_crisis_level)
            {
                $out .= "*";
            }
            else
            {
                $out .= " ";
            }
        }
        $out .= "]";
    }
    return $out;
}
sub print_crisis_bar
{
    my $self = shift;
    return $self->status_color . $self->print_grey_crisis_bar . color("reset");
}

sub change_factor
{
    my $self = shift;
    my $delta = shift;
    my $new_factor = $self->factor + $delta;
    $new_factor = $new_factor < 0 ? 0 : $new_factor > 100 ? 100 : $new_factor;
    $self->factor($new_factor);
}

sub escalate_crisis
{
    my $self = shift;
    if($self->crisis_level < CRISIS_MAX_FACTOR)
    {
        $self->crisis_level($self->crisis_level() + 1);
    }
}
sub cooldown_crisis
{
    my $self = shift;
    if($self->crisis_level > 0)
    {
        $self->crisis_level($self->crisis_level() - 1);
    }
}
sub is_crisis
{
    my $self = shift;
    return $self->crisis_level > 0;
}
sub is_max_crisis
{
    my $self = shift;
    return $self->get_crisis_level() == CRISIS_MAX_FACTOR;
}
sub dump
{
    my $self = shift;
    my $indent = shift || "";
    my $io = shift;
    print {$io} $indent . join(";", $self->node1, $self->node2, $self->factor, $self->crisis_level) . "\n";
}


1;
