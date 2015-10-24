package BalanceOfPower::Role::Warlord;

use strict;
use v5.10;

use Moo::Role;

use Term::ANSIColor;
use Data::Dumper;

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw( as_title );
use BalanceOfPower::Relations::Crisis;
use BalanceOfPower::Relations::War;

requires 'get_nation';
requires 'get_hates';
requires 'occupy';
requires 'broadcast_event';
requires 'send_event';
requires 'empire';
requires 'get_group_borders';
requires 'get_allies';
requires 'supported';
requires 'military_support_garbage_collector';
requires 'random';
requires 'change_diplomacy';
requires 'get_crises';
requires 'delete_crisis';

has wars => (
    is => 'ro',
    default => sub { BalanceOfPower::Relations::RelPack->new() },
    handles => { at_war => 'first_link_for_node',
                 add_war => 'add_link',
                 get_wars => 'links_for_node',
                 war_exists => 'exists_link',
                 delete_war => 'delete_link',
                 get_attackers => 'links_for_node2'
               }
);



sub available_for_war
{
    my $self = shift;
    my $nation = shift;
    my @crises = $self->get_crises($nation);
    my @out = ();
    my @coalition = $self->empire($nation);
    foreach my $c (@crises)
    {
        my $n = $c->destination($nation);
        if(! $self->at_war($n))
        {
            push @out, $n;
        }
    }
    @out = $self->get_group_borders(\@coalition, \@out);
    return @out;
}

sub at_civil_war
{
    my $self = shift;
    my $n = shift;
    my $nation = $self->get_nation($n);
    return $nation->internal_disorder_status eq 'Civil war';
}

sub war_busy
{
    my $self = shift;
    my $n = shift;
    return $self->at_civil_war($n) || $self->at_war($n);
}



sub create_war
{
    my $self = shift;
    my $attacker = shift || "";
    my $defender = shift || "";

    if(! $self->war_exists($attacker->name, $defender->name))
    {
        $self->broadcast_event("CRISIS BETWEEN " . $attacker->name . " AND " . $defender->name . " BECAME WAR", $attacker->name, $defender->name); 
        my @attacker_coalition = $self->empire($attacker->name);
        @attacker_coalition = grep { ! $self->at_war($_) } @attacker_coalition;
        @attacker_coalition = grep { ! $self->at_civil_war($_) } @attacker_coalition;
        my @defender_coalition = $self->empire($defender->name);
        @defender_coalition = grep { ! $self->at_war($_) } @defender_coalition;
        @defender_coalition = grep { ! $self->at_civil_war($_) } @defender_coalition;
    
        #Allies management
        my @attacker_allies = $self->get_allies($attacker->name);
        my @defender_allies = $self->get_allies($defender->name);
        for(@attacker_allies)
        {
            my $ally_name = $_->destination($attacker->name);
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
            my $ally_name = $_->destination($defender->name);
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
        my @couples_factions;
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
            @potential_attackers = $self->shuffle("War creation. Choosing attackers", @potential_attackers);
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
                    @potential_defenders = $self->shuffle("War creation. Choosing defenders", @potential_defenders);
                    $defend_now = $potential_defenders[0];
                    $searching = 0;
                }
                else
                {
                    $free_level++;
                }
            }
            push @war_couples, [$attack_now, $defend_now];
            push @couples_factions, $faction;
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
        my $war_id = time;
        $self->add_war( BalanceOfPower::Relations::War->new(node1 => $attacker->name, 
                                                      node2 => $defender->name,
                                                      attack_leader => $attacker->name,
                                                      war_id => $war_id,
                                                      node1_faction => 0,
                                                      node2_faction => 1) );
        $attacker_leaders{$defender->name} = $attacker->name;                                              
        $self->broadcast_event("WAR BETWEEN " . $attacker->name . " AND " .$defender->name . " STARTED", $attacker->name, $defender->name);
        my $faction_counter = 0;
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
            my $faction1;
            my $faction2;
            if($couples_factions[$faction_counter] == 0)
            {
                $faction1 = 0;
                $faction2 = 1;
            }
            else
            {
                $faction1 = 1;
                $faction2 = 0;
            }
            $self->add_war(BalanceOfPower::Relations::War->new(node1 => $c->[0], 
                                                          node2 => $c->[1],
                                                          attack_leader => $leader,
                                                          war_id => $war_id,
                                                          node1_faction => $faction1,
                                                          node2_faction => $faction2));
            $self->broadcast_event("WAR BETWEEN " . $c->[0] . " AND " . $c->[1] . " STARTED (LINKED TO WAR BETWEEN " . $attacker->name . " AND " .$defender->name . ")", $c->[0], $c->[1]);
        }
    }
}

sub army_for_war
{
    my $self = shift;
    my $nation = shift;
    my @supported = $self->supported($nation->name);
    my $army = $nation->army;
    for(@supported)
    {
        $army += $_->army;
    }
    return $army;
}

sub damage_from_battle
{
    my $self = shift;
    my $nation = shift;
    my $damage = shift;
    my @supported = $self->supported($nation->name);
    my $flip = 0;
    my $army_damage = 0;
    while($damage > 0)
    {
        if($flip <= $#supported)
        {
            if($supported[$flip]->army > 0)
            {
                $supported[$flip]->casualities(1);
                $damage--;
            }
        }
        else
        {
            $army_damage++;
            $damage--;
        }
        $flip++;
        if($flip > $#supported + 1)
        {
            $flip = 0;
        }
    }
    $nation->add_army(-1 * $army_damage);
    for(@supported)
    {
        if($_->army <= 0)
        {
            $self->broadcast_event("MILITARY SUPPORT TO " . $_->node2 . " BY " . $_->node1 . " DESTROYED", $_->node1, $_->node2);
        }
    }
    $self->military_support_garbage_collector();
}

sub fight_wars
{
    my $self = shift;
    my %losers;
    foreach my $w ($self->wars->all())
    {
        #As Risiko
        $self->broadcast_event("WAR BETWEEN " . $w->node1 . " AND " . $w->node2 . " GO ON", $w->node1, $w->node2);
        my $attacker = $self->get_nation($w->node1);
        my $defender = $self->get_nation($w->node2);
        my $attacker_army = $self->army_for_war($attacker);
        my $defender_army = $self->army_for_war($defender);
        my $attack = $attacker_army >= ARMY_FOR_BATTLE ? ARMY_FOR_BATTLE : $attacker_army;
        my $defence = $defender_army >= ARMY_FOR_BATTLE ? ARMY_FOR_BATTLE : $defender_army;
        my $attacker_damage = 0;
        my $defender_damage = 0;
        my $counter = $attack < $defence ? $attack : $defence;
        for(my $i = 0; $i < $counter; $i++)
        {
            my $att = $self->random(1, 6, "War risiko: throw for attacker " . $attacker->name);
            my $def = $self->random(1, 6, "War risiko: throw for defender " . $defender->name);
            if($att > $def)
            {
                $defender_damage++;
            }
            else
            {
                $attacker_damage++;
            }
        }
        for($self->supported($attacker->name))
        {
            my $supporter_n = $_->start($attacker->name);
            $self->broadcast_event("RELATIONS BETWEEN " . $defender->name . " AND " . $supporter_n . " CHANGED FOR WAR WITH " . $attacker->name, $attacker->name, $defender->name, $supporter_n);
            $self->change_diplomacy($defender->name, $supporter_n, -1 * DIPLOMACY_MALUS_FOR_SUPPORT);
        }
        for($self->supported($defender->name))
        {
            my $supporter_n = $_->start($defender->name);
            $self->broadcast_event("RELATIONS BETWEEN " . $attacker->name . " AND " . $supporter_n . " CHANGED FOR WAR WITH " . $defender->name, $attacker->name, $defender->name, $supporter_n);
            $self->change_diplomacy($attacker->name, $supporter_n, -1 * DIPLOMACY_MALUS_FOR_SUPPORT);
        }

        $self->damage_from_battle($attacker, $attacker_damage);
        $self->damage_from_battle($defender, $defender_damage);
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

sub print_wars
{
    my $self = shift;
    my %grouped_wars;
    my $out = "";
    $out .= as_title("WARS\n===\n");
    foreach my $w ($self->wars->all())
    {
        if(! exists $grouped_wars{$w->war_id})
        {
            $grouped_wars{$w->war_id} = [];
        }
        push @{$grouped_wars{$w->war_id}}, $w; 
    }
    foreach my $k (keys %grouped_wars)
    {
        $out .= "### WAR $k\n";
        foreach my $w ( @{$grouped_wars{$k}})
        {
            my $nation1 = $self->get_nation($w->node1);
            my $nation2 = $self->get_nation($w->node2);
            $out .= $w->print($nation1->army, $nation2->army);
            $out .= "\n";
        }
        $out .= "---\n";
    }
    $out .= "\n";
    foreach my $n (@{$self->nation_names})
    {
        if($self->at_civil_war($n))
        {
            $out .= "$n is fighting civil war\n";
        }
    }
    return $out;
}
1;
