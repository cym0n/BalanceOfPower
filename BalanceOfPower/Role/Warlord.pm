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
requires 'conquer';
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
    my @used = ();
    for(my $i = 0; $i < CRISIS_GENERATION_TRIES; $i++)
    {
        my $chosen = $self->crisis_generator_round(@used);
        if($chosen)
        {
            push @used, $chosen;
        }
    }

}

sub crisis_generator_round
{
    my $self = shift;
    my @blacklist = shift;
    my @hates = grep {
                        my $a = $_;
                        my $exit = undef;
                        $exit = 1 if(! @blacklist);
                        if(! $exit)
                        {
                            for(@blacklist)
                            {
                                my $couple = $_;
                                if($a->involve($couple->[0], $couple->[1]))
                                {
                                    $exit = 0;
                                }
                            }
                        }
                        $exit = 1 if(! $exit);
                        $exit;
                     } shuffle $self->get_hates();
    my @crises = grep {
                        my $a = $_;
                        my $exit = undef;
                        $exit = 1 if(! @blacklist);
                        if(! $exit)
                        {
                            for(@blacklist)
                            {
                                my $couple = $_;
                                if($a->involve($couple->[0], $couple->[1]))
                                {
                                    $exit = 0;
                                }
                            }
                        }
                        $exit = 1 if(! $exit);
                        $exit;
                     } shuffle @{$self->crises};
                     
    my $picked_hate = undef; 
    my $picked_crisis = undef;
    if(@hates)
    {
        $picked_hate = $hates[0];
    }
    if(@crises)
    {
        $picked_crisis = $crises[0];
    }
   

    my $action = random(0, CRISIS_GENERATOR_NOACTION_TOKENS + 3);
    if($action == 0) #NEW CRISIS
    {
        return undef if ! $picked_hate; 
        if(! $self->war_exists($picked_hate->node1, $picked_hate->node2))
        {
            $self->create_or_escalate_crisis($picked_hate->node1, $picked_hate->node2);
            return [$picked_hate->node1, $picked_hate->node2];
        }
    }
    elsif($action == 1) #ESCALATE
    {
        return undef if ! $picked_crisis; 
        if(! $self->war_exists($picked_crisis->node1, $picked_crisis->node2))
        {
            $self->create_or_escalate_crisis($picked_crisis->node1, $picked_crisis->node2);
        }
        return [$picked_crisis->node1, $picked_crisis->node2];
    }
    elsif($action == 2) #COOL DOWN
    {
        return undef if ! $picked_crisis; 
        if(! $self->war_exists($picked_crisis->node1, $picked_crisis->node2))
        {
            $self->cool_down($picked_crisis->node1, $picked_crisis->node2);
        }
        return [$picked_crisis->node1, $picked_crisis->node2];
    }
    elsif($action == 3) #ELIMINATE
    {
        return undef if ! $picked_crisis; 
        if(! $self->war_exists($crises[0]->node1, $crises[0]->node2))
        {
            $self->delete_crisis($crises[0]->node1, $crises[0]->node2);
        }
        return [$picked_crisis->node1, $picked_crisis->node2];
    }
    else
    {
        return undef;
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
sub at_war
{
    my $self = shift;
    my $n = shift;
    foreach my $r (@{$self->wars})
    {
        return $r if($r->has_node($n));
    }
    return undef;
}



sub create_war
{
    my $self = shift;
    my $attacker = shift || "";
    my $defender = shift || "";

    if(! $self->war_exists($attacker->name, $defender->name))
    {
        $self->register_event("CRISIS BETWEEN " . $attacker->name . " AND " . $defender->name . " BECAME WAR", $attacker->name, $defender->name); 
        push @{$self->wars}, BalanceOfPower::War->new(node1 => $attacker->name, node2 => $defender->name);
        $self->register_event("WAR BETWEEN " . $attacker->name . " AND " .$defender->name . " STARTED", $attacker->name, $defender->name);
    }
}

sub get_war
{
    my $self = shift;
    my $node1 = shift;
    foreach my $r (@{$self->wars})
    {
        return $r if($r->has_node($node1));
    }
    return undef;
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
        #Defender wins
        $attacker->register_event("WAR WITH " . $defender->name . " LOST. WE RETREAT");
        $defender->register_event("WAR WITH " . $attacker->name . " WON.");
    }
    elsif($winner eq 'attacker') 
    {
        #Attacker wins
        $defender->internal_disorder(AFTER_CONQUERED_INTERNAL_DISORDER);
        $self->conquer($attacker, $defender); 
        $self->delete_crisis($attacker->name, $defender->name);
    }
    elsif($winner eq 'defender-civilwar')
    {
        #Attacker has civil war at home and can't go on fighting
        $attacker->register_event("WAR WITH " . $defender->name . " LOST. WE RETREAT");
        $defender->register_event("WAR WITH " . $attacker->name . " WON.");
    }
    elsif($winner eq 'attacker-civilwar')
    {
        #Civil war helps attacker to win
        $attacker->register_event("WAR WITH " . $defender->name . " WON.");
        $defender->register_event("WAR WITH " .$attacker->name . " IS LOST. GOVERNMENT IN CHAOS");
        $self->under_influence($attacker, $defender); 
        $defender->internal_disorder(AFTER_CONQUERED_INTERNAL_DISORDER);
        $self->delete_crisis($attacker->name, $defender->name);
    }
        
    @{$self->wars} = grep { ! $_->is_between($attacker->name, $defender->name) } @{$self->wars};
    
}
1;
