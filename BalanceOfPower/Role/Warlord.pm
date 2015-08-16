package BalanceOfPower::Role::Warlord;

use strict;
use v5.10;

use Moo::Role;

use List::Util qw(shuffle);
use Data::Dumper;

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw(prev_year next_year random random10 get_year_turns);
use BalanceOfPower::Relations::Crisis;
use BalanceOfPower::Relations::War;

requires 'get_nation';
requires 'get_hates';
requires 'occupy';
requires 'broadcast_event';
requires 'send_event';
requires 'coalition';
requires 'get_group_borders';
requires 'get_allies';

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
            $self->broadcast_event($event, $node1, $node2);
        }
    }
    else
    {
        push @{$self->crises}, BalanceOfPower::Relations::Crisis->new(node1 => $node1, node2 => $node2);
        $self->broadcast_event("CRISIS BETWEEN $node1 AND $node2 STARTED", $node1, $node2);
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
            $self->broadcast_event("CRISIS BETWEEN $node1 AND $node2 COOLED DOWN", $node1, $node2);
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
    $self->broadcast_event($event, $node1, $node2);
    
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
sub at_civil_war
{
    my $self = shift;
    my $n = shift;
    my $nation = $self->get_nation($n);
    if($nation->internal_disorder_status eq 'Civil war')
    {
        return 1;
    }
    else
    {
        return 0;
    }
}



sub create_war
{
    my $self = shift;
    my $attacker = shift || "";
    my $defender = shift || "";

    if(! $self->war_exists($attacker->name, $defender->name))
    {
        $self->broadcast_event("CRISIS BETWEEN " . $attacker->name . " AND " . $defender->name . " BECAME WAR", $attacker->name, $defender->name); 
        my @attacker_coalition = $self->coalition($attacker->name);
        @attacker_coalition = grep { ! $self->at_war($_) } @attacker_coalition;
        @attacker_coalition = grep { ! $self->at_civil_war($_) } @attacker_coalition;
        my @defender_coalition = $self->coalition($defender->name);
        @defender_coalition = grep { ! $self->at_war($_) } @defender_coalition;
        @defender_coalition = grep { ! $self->at_civil_war($_) } @defender_coalition;
    
        #Allies management
        my @attacker_allies = $self->get_allies($attacker->name);
        my @defender_allies = $self->get_allies($defender->name);
        for(@attacker_allies)
        {
            my $ally_name = $_;
            my $ally = $self->get_nation( $ally_name );
            if($ally->good_prey($defender, $self, ALLY_CONFLICT_LEVEL_FOR_INVOLVEMENT, 0 ))
            {
                if(! grep { $_ eq $ally_name } @attacker_coalition)
                {
                    push @attacker_coalition, $ally_name;
                    $ally->register_event("JOIN WAR AS ALLY OF " . $attacker->name ." AGAINST " . $defender->name);
                }
            }
        }
        for(@defender_allies)
        {
            my $ally_name = $_;
            my $ally = $self->get_nation( $ally_name );
            if($ally->good_prey($attacker, $self, ALLY_CONFLICT_LEVEL_FOR_INVOLVEMENT, 0 ))
            {
                if(! grep { $_ eq $ally_name } @defender_coalition)
                {
                    push @defender_coalition, $ally_name;
                    $ally->register_event("JOIN WAR AS ALLY OF " . $defender->name ." AGAINST " . $attacker->name);
                }
            }
        }

        my @attacker_targets = $self->get_group_borders(\@attacker_coalition, \@defender_coalition);
        my @defender_targets = $self->get_group_borders(\@defender_coalition, \@attacker_coalition);
        my @war_couples;
        my %used;
        for(@attacker_coalition, @defender_coalition)
        {
            $used{$_} = 0;
        }
        #push @war_couples, [$attacker->name, $defender->name];
        $used{$attacker->name} = 1;
        $used{$defender->name} = 1;
        my $faction = 1;
        my $done = 0;
        my $faction0_done = 0;
        my $faction1_done = 0;
        while(! $done)
        {
            my @potential_attackers;
            if($faction == 0)
            {
                @potential_attackers = grep { $used{$_} == 0 } @attacker_coalition;
            }
            elsif($faction == 1)
            {
                @potential_attackers = grep { $used{$_} == 0 } @defender_coalition;
            }
            if(@potential_attackers == 0)
            {
                if($faction0_done == 1 && $faction == 1 ||
                   $faction1_done == 1 && $faction == 0)
                {
                    $done = 1;
                    last;
                } 
                else
                {
                    if($faction == 0)
                    {
                        $faction0_done = 1;
                        $faction = 1;
                    }
                    else
                    {
                        $faction1_done = 1;
                        $faction = 0;
                    }
                    next;
                }
                
            }
            @potential_attackers = shuffle @potential_attackers;
            my $attack_now = $potential_attackers[0];
            my $defend_now;
            my $free_level = 0;
            my $searching = 1;
            while($searching)
            {
                my @potential_defenders;
                if($faction == 0)
                {
                    @potential_defenders = grep { $used{$_} <= $free_level } @defender_coalition;
                }
                elsif($faction == 1)
                {
                    @potential_defenders = grep { $used{$_} <= $free_level } @attacker_coalition;
                }
                if(@potential_defenders > 0)
                {
                    @potential_defenders = shuffle @potential_defenders;
                    $defend_now = $potential_defenders[0];
                    $searching = 0;
                }
                else
                {
                    $free_level++;
                }
            }
            push @war_couples, [$attack_now, $defend_now];
            $used{$attack_now} += 1;
            $used{$defend_now} += 1;
            if($faction == 0)
            {
                $faction = 1;
            }
            else
            {
                $faction = 0;
            }
        }
        my %attacker_leaders;
        push @{$self->wars}, BalanceOfPower::Relations::War->new(node1 => $attacker->name, 
                                                      node2 => $defender->name,
                                                      attack_leader => $attacker->name);
        $attacker_leaders{$defender->name} = $attacker->name;                                              
        $self->broadcast_event("WAR BETWEEN " . $attacker->name . " AND " .$defender->name . " STARTED", $attacker->name, $defender->name);
        foreach my $c (@war_couples)
        {
            my $leader;
            if(exists $attacker_leaders{$c->[1]})
            {
                $leader = $attacker_leaders{$c->[1]}
            }
            else
            {
                $leader = $c->[0];
                $attacker_leaders{$c->[1]} = $c->[0];
            }
            push @{$self->wars}, BalanceOfPower::Relations::War->new(node1 => $c->[0], 
                                                          node2 => $c->[1],
                                                          attack_leader => $leader);
            $self->broadcast_event("WAR BETWEEN " . $c->[0] . " AND " . $c->[1] . " STARTED (LINKED TO WAR BETWEEN " . $attacker->name . " AND " .$defender->name . ")", $c->[0], $c->[1]);
        }
    }
}

sub get_wars
{
    my $self = shift;
    my $node1 = shift;
    my @wars = ();
    if($node1)
    {
        return grep { $_->has_node($node1) } @{$self->wars};
    }
    else
    {
        return @{$self->wars};
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
sub delete_war
{
    my $self = shift;
    my $node1 = shift;;
    my $node2 = shift;
    return if ! $self->war_exists($node1, $node2);
    @{$self->wars} = grep { ! $_->involve($node1, $node2) } @{$self->wars};
}

sub get_attackers
{
    my $self = shift;
    my $n1 = shift;
    my @attacks = ();
    foreach my $r (@{$self->wars})
    {
        if($r->node2 eq $n1)
        {
            push @attacks, $r->node1;
        }
    }
    return @attacks;
}

sub fight_wars
{
    my $self = shift;
    my %losers;
    foreach my $w (@{$self->wars})
    {
        #As Risiko
        my $attacker = $self->get_nation($w->node1);
        my $defender = $self->get_nation($w->node2);
        my $attack = $attacker->army >= ARMY_FOR_BATTLE ? ARMY_FOR_BATTLE : $attacker->army;
        my $defence = $defender->army >= ARMY_FOR_BATTLE ? ARMY_FOR_BATTLE : $defender->army;
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
        $attacker->register_event("CASUALITIES IN WAR WITH " . $defender->name . ": $attacker_damage");
        $defender->register_event("CASUALITIES IN WAR WITH " . $attacker->name . ": $defender_damage");
        if($attacker->army == 0)
        {
            $losers{$attacker->name} = 1;
        }
        elsif($defender->army == 0)
        {
            $losers{$defender->name} = 1;
        }
    }
    for(keys %losers)
    {
        $self->lose_war($_);
    }
}

sub lose_war
{
    my $self = shift;
    my $loser = shift;
    my $internal_disorder ||= 0;
    my @wars = $self->get_wars($loser);
    my $retreat_penality = 0;
    my @conquerors = ();
    my $conquerors_leader = "";
    foreach my $w (@wars)
    {
        my $other;
        my $winner_role;
        if($w->node1 eq $loser)
        {
            #Loser is the attacker
            $retreat_penality = 1;
            $other = $w->node2;
            $winner_role = "[DEFENDER]";
            $self->send_event("RETREAT FROM " . $other, $loser);
        }
        elsif($w->node2 eq $loser)
        {
            #Loser is the defender
            $other = $w->node1;
            push @conquerors, $w->node1;
            $self->delete_crisis($loser, $other);
            $conquerors_leader = $w->attack_leader;
            $winner_role = "[ATTACKER]";
        }
        $self->broadcast_event("WAR BETWEEN $other AND $loser WON BY $other $winner_role", $other, $loser);
        $self->delete_war($other, $loser);
    }
    if(@conquerors > 0)
    {
        $self->occupy($loser, \@conquerors, $conquerors_leader, $internal_disorder);  
    }
}
1;
