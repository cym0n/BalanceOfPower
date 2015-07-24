package BalanceOfPower::Role::Warlord;

use strict;
use Moo::Role;

use List::Util qw(shuffle);
use Data::Dumper;

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw(prev_year next_year random random10 get_year_turns);
use BalanceOfPower::Crisis;

requires 'get_nation';
requires 'get_hates';
requires 'register_event';

has crises => (
    is => 'rw',
    default => sub { [] }
);

sub crisis_generator
{
    my $self = shift;
    my $action = random(0, CRISIS_GENERATOR_NOACTION_TOKENS + 3);
    if($action == 0) #NEW CRYSIS
    {
        my @hates = shuffle $self->get_hates();
        $self->create_or_escalate_crisis($hates[0]->node1, $hates[0]->node2);
    }
    elsif($action == 1) #ESCALATE
    {
        my @crises = shuffle @{$self->crises};
        if(@crises > 0)
        {
            $self->create_or_escalate_crisis($crises[0]->node1, $crises[0]->node2);
        }
    }
    elsif($action == 2) #COOL DOWN
    {
        my @crises = shuffle @{$self->crises};
        if(@crises > 0)
        {
            $self->cool_down($crises[0]->node1, $crises[0]->node2);
        }
    }
    elsif($action == 3) #ELIMINATE
    {
        my @crises = shuffle @{$self->crises};
        if(@crises > 0)
        {
            $self->delete_crisis($crises[0]->node1, $crises[0]->node2);
        }
    }
}
sub create_or_escalate_crisis
{
    my $self = shift;
    my $node1 = shift || "";
    my $node2 = shift || "";
    if(my $crisis = $self->crisis_exists($node1, $node2))
    {
        if($crisis->factor < CRISIS_MAX_FACTOR)
        {
            $crisis->factor($crisis->factor +1);
            my $event = "CRISIS BETWEEN $node1 AND $node2 ESCALATES";
            if($crisis->factor == CRISIS_MAX_FACTOR)
            {
               $event .= " TO MAX LEVEL"; 
            }
            $self->register_event($event, $node1, $node2);
        }
    }
    else
    {
        push @{$self->crises}, BalanceOfPower::Crisis->new(node1 => $node1, node2 => $node2);
        $self->register_event("CRISIS BETWEEN $node1 AND $node2 STARTED", $node1, $node2);
    }
}
sub cool_down
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    if(my $crisis = $self->crisis_exists($node1, $node2))
    {
        if($crisis->factor == 1)
        {
            $self->delete_crisis($node1, $node2);
        }
        else
        {
            $crisis->factor($crisis->factor - 1);
            $self->register_event("CRISIS BETWEEN $node1 AND $node2 COOLED DOWN", $node1, $node2);
        }
    }
}

sub delete_crisis
{
    my $self = shift;
    my $node1 = shift;;
    my $node2 = shift;
    return if ! $self->crisis_exists($node1, $node2);
    my $n1 = $self->get_nation($node1);
    my $n2 = $self->get_nation($node2);
    
    @{$self->crises} = grep { ! $_->is_between($node1, $node2) } @{$self->crises};
    my $event = "CRISIS BETWEEN $node1 AND $node2 ENDED";
    $self->register_event($event, $node1, $node2);
    
}

sub crisis_exists
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    foreach my $r (@{$self->crises})
    {
        return $r if($r->is_between($node1, $node2));
    }
    return undef;
}

sub print_crises
{
    my $self = shift;
    my $n = shift;
    my $out;
    foreach my $b (@{$self->crises})
    {
        if($b->has_node($n))
        {
            $out .= $b->print($n) . "\n";
        }
    }
    return $out;
}

1;
