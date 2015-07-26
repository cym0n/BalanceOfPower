package BalanceOfPower::Role::Warlord;

use strict;
use Moo::Role;

use List::Util qw(shuffle);
use Data::Dumper;

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw(prev_year next_year random random10 get_year_turns);
use BalanceOfPower::Crisis;
use BalanceOfPower::War;

requires 'get_nation';
requires 'get_hates';
requires 'register_event';

has crises => (
    is => 'rw',
    default => sub { [] }
);

has wars => (
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
        if(! $self->war_exists($hates[0]->node1, $hates[0]->node2))
        {
            $self->create_or_escalate_crisis($hates[0]->node1, $hates[0]->node2);
        }
    }
    elsif($action == 1) #ESCALATE
    {
        my @crises = shuffle @{$self->crises};
        if(@crises > 0)
        {
            if(! $self->war_exists($crises[0]->node1, $crises[0]->node2))
            {
                $self->create_or_escalate_crisis($crises[0]->node1, $crises[0]->node2);
            }
        }
    }
    elsif($action == 2) #COOL DOWN
    {
        my @crises = shuffle @{$self->crises};
        if(@crises > 0)
        {
            if(! $self->war_exists($crises[0]->node1, $crises[0]->node2))
            {
                $self->cool_down($crises[0]->node1, $crises[0]->node2);
            }
        }
    }
    elsif($action == 3) #ELIMINATE
    {
        my @crises = shuffle @{$self->crises};
        if(@crises > 0)
        {
            if(! $self->war_exists($crises[0]->node1, $crises[0]->node2))
            {
                $self->delete_crisis($crises[0]->node1, $crises[0]->node2);
            }
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

sub get_crises
{
    my $self = shift;
    my $node = shift;
    my @crises = ();
    foreach my $r (@{$self->crises})
    {
        push @crises, $r if $r->has_node($node);
    }
    return @crises;
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



sub create_war
{
    my $self = shift;
    my $node1 = shift || "";
    my $node2 = shift || "";
    if(! $self->war_exists($node1, $node2))
    {
        push @{$self->wars}, BalanceOfPower::War->new(node1 => $node1, node2 => $node2);
        $self->register_event("WAR BETWEEN $node1 AND $node2 STARTED", $node1, $node2);
    }
}



sub war_exists
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    foreach my $r (@{$self->wars})
    {
        return $r if($r->involve($node1, $node2));
    }
    return undef;
}

sub fight_wars
{
    my $self = shift;
    foreach my $w (@{$self->wars})
    {
        #As Risiko
        my $attacker = $self->get_nation($w->node1);
        my $defender = $self->get_nation($w->node2);
        my $attack = $attacker->army >= 30 ? 30 : $attacker->army;
        my $defence = $defender->army >= 30 ? 30 : $defender->army;
        my $attacker_damage = 0;
        my $defender_damage = 0;
        my $counter = $attack < $defence ? $attack : $defence;
        for(my $i = 0; $i < $counter; $i++)
        {
            my $att = random(1, 6);
            my $def = random(1, 6);
            if($att > $def)
            {
                $defender_damage++;
            }
            else
            {
                $attacker_damage++;
            }
        }
        $attacker->add_army(-1 * $attacker_damage);
        $defender->add_army(-1 * $defender_damage);
        if($attacker->army == 0)
        {
            $self->end_war($attacker, $defender, 'defender');
        }
        elsif($defender->army == 0)
        {
            $self->end_war($attacker, $defender, 'attacker');
        }
        else
        {
            $attacker->register_event("CASUALITIES IN WAR WITH " . $defender->name . ": $attacker_damage");
            $defender->register_event("CASUALITIES IN WAR WITH " . $attacker->name . ": $defender_damage");
        }
    }
}

sub end_war
{
    my $self = shift;
    my $attacker = shift;;
    my $defender = shift;
    my $winner = shift;
    return if ! $self->war_exists($attacker->name, $defender->name);
    $self->register_event("WAR BETWEEN " . $attacker->name . " AND ". $defender->name . " ENDS", $attacker->name, $defender->name);
    if($winner eq 'defender')
    {
        $attacker->register_event("RETREAT FROM " . $defender->name . ". WAR IS LOST");
        $defender->register_event("NATION DEFEATED " . $attacker->name . ". WAR IS WON");
    }
    elsif($winner eq 'attacker')
    {
        $attacker->register_event("CONQUER " . $defender->name . ". WAR IS WON");
        $defender->register_event("NATION CONQUERED BY " . $attacker->name . ". WAR IS LOST");
        $defender->internal_disorder(AFTER_CONQUERED_INTERNAL_DISORDER);
        $defender->situation( { status => 'conquered',
                                by => $attacker->name,
                                clock => 0 } );
    }
    $attacker->at_war(0);
    $defender->at_war(0);
        
    @{$self->wars} = grep { ! $_->is_between($attacker->name, $defender->name) } @{$self->wars};
    
}
1;
