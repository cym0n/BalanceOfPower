package BalanceOfPower::Nation::Role::IA;

use strict;
use v5.10;
use Moo::Role;
use Array::Utils qw(intersect);

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw( prev_turn );

sub decision
{
    my $self = shift;
    my $world = shift;
    my @advisors;
    if($world->at_war($self->name) || $world->at_civil_war($self->name))
    {
        @advisors = ('military');
    }
    else
    {
        @advisors = ('domestic', 'economy', 'military');
    }
    @advisors = $world->shuffle("Choosing advisor for ".$self->name, @advisors);
    foreach my $a (@advisors)
    {
        my $decision = undef;
        if($a eq 'domestic')
        {
            $decision = $self->domestic_advisor($world);
        }
        elsif($a eq 'economy')
        {
            $decision = $self->economy_advisor($world);
        }
        elsif($a eq 'military')
        {
            $decision = $self->military_advisor($world);
        }
        return $self->name .  ": " . $decision if($decision);
    }
    return undef;
}

### DOMESTIC ###
# Orders:
#   LOWER DISORDER
#   BOOST PRODUCTION
#   TREATY NAG
sub domestic_advisor
{
    my $self = shift;
    my $world = shift;
    if($self->internal_disorder > WORRYING_LIMIT && $self->production_for_domestic > DOMESTIC_BUDGET)
    {
        return "LOWER DISORDER";
    }
    elsif($self->production < EMERGENCY_PRODUCTION_LIMIT)
    {
        return "BOOST PRODUCTION";
    }
    elsif($self->prestige >= TREATY_PRESTIGE_COST)
    {
        #Scanning neighbors
        my @near = $world->near_nations($self->name, 1);
        my @friends = $world->get_nations_with_status($self->name, ['NEUTRAL', 'FRIENDSHIP', 'ALLIANCE']);
        my @friendly_neighbors = $world->shuffle("Mixing neighbors to choose about NAG treaty", intersect(@near, @friends));
        my @ordered_friendly_neighbors = ();
        my $dangerous_neighbor = 0;
        for(@friendly_neighbors)
        {
            my $n = $_;
            if(! $world->exists_treaty($self->name, $n))
            {
                my @supporter = $world->supported($n);
                if(@supporter > 0)
                {
                    my $supporter_nation = $supporter[0]->node1;
                    if($supporter_nation eq $self->name)
                    {
                        #I'm the supporter of this nation!
                        push @ordered_friendly_neighbors, { nation => $n,
                                                            interest => 0 };
                    }
                    else
                    {
                        if($world->crisis_exists($self->name, $supporter_nation))
                        {
                            push @ordered_friendly_neighbors, { nation => $n,
                                                                interest => 100 };
                            $dangerous_neighbor = 1;
                        }
                        elsif($world->diplomacy_status($self->name, $supporter_nation) eq 'HATE')
                        {
                            push @ordered_friendly_neighbors, { nation => $n,
                                                            interest => 10 };
                        }
                        else
                        {
                            push @ordered_friendly_neighbors, { nation => $n,
                                                                interest => 2 };
                        }
                    }
                }
                else
                {
                    push @ordered_friendly_neighbors, { nation => $n,
                                                        interest => 1 };
                }
            }
        }
        if(@ordered_friendly_neighbors > 0 && $dangerous_neighbor)
        {
            @ordered_friendly_neighbors = sort { $b->{interest} <=> $a->{interest} } @ordered_friendly_neighbors;
            return "TREATY NAG WITH " . $ordered_friendly_neighbors[0]->{nation};
        }
        else
        {
            #Scanning crises
            my @crises = $world->get_crises($self->name);
            if(@crises > 0)
            {
                foreach my $c ($world->shuffle("Mixing crisis for war for " . $self->name, @crises))
                {
                    #NAG with enemy supporter
                    my $enemy = $c->destination($self->name);
                    my @supporter = $world->supported($enemy);
                    if(@supporter > 0)
                    {
                        my $supporter_nation = $supporter[0]->node1;
                        if($supporter_nation ne $self->name &&
                           $world->diplomacy_status($self->name, $supporter_nation) ne 'HATE' &&
                           ! $world->exists_treaty($self->name, $supporter_nation))
                        {
                            return "TREATY NAG WITH " . $supporter_nation;
                        } 
                    }
                    #NAG with enemy ally
                    my @allies = $world->get_allies($enemy);
                    for($world->shuffle("Mixing allies of enemy for a NAG", @allies))
                    {
                        my $all = $_->destination($enemy);
                        if($all ne $self->name &&
                           $world->diplomacy_status($self->name, $all) ne 'HATE' &&
                           ! $world->exists_treaty($self->name, $all))
                        {
                            return "TREATY NAG WITH " . $all;
                        } 
                    }
                }
            }
            if(@ordered_friendly_neighbors > 0)
            {
                @ordered_friendly_neighbors = sort { $b->{interest} <=> $a->{interest} } @ordered_friendly_neighbors;
                return "TREATY NAG WITH " . $ordered_friendly_neighbors[0]->{nation};
            }
            return undef;
        }
    }
    else
    {
        return undef;
    }
}

### ECONOMY ###
# Orders:
#   DELETE TRADEROUTE
#   ADD ROUTE
#   TREATY COM
#   ECONOMIC AID
sub economy_advisor
{
    my $self = shift;
    my $world = shift;
    my $prev_year = prev_turn($self->current_year);
    my @trade_ok = $self->get_events("TRADE OK", $prev_year);
    if($self->prestige >= TREATY_PRESTIGE_COST && @trade_ok > 0)
    {
        for(@trade_ok)
        {
            my $route = $_;
            $route =~ s/^TRADE OK //;
            $route =~ s/ \[.*$//;
            my $status = $world->diplomacy_status($self->name, $route);
            if(! $world->exists_treaty($self->name, $route) && $status ne 'HATE')
            {
                return "TREATY COM WITH " . $route;
            }
        }
    }
    my @trade_ko = $self->get_events("TRADE KO", $prev_year);
    if(@trade_ko > 1)
    {
        #my $to_delete = $trade_ko[$#trade_ko];
        #$to_delete =~ s/TRADE KO //;
        #return $self->name . ": DELETE TRADEROUTE " . $self->name . "->" . $to_delete;
        for(@trade_ko)
        {
            my $to_delete = $_;
            $to_delete =~ s/TRADE KO //;
            if(! $world->exists_treaty_by_type($self->name, $to_delete, 'commercial'))
            {
                return "DELETE TRADEROUTE " . $self->name . "->" . $to_delete;   
            }
        }
    }
    elsif(@trade_ko == 1)
    {
        my @older_trade_ko = $self->get_events("TRADE KO", prev_turn($prev_year));
        if(@older_trade_ko > 0)
        {
            my $to_delete = $trade_ko[$#trade_ko];
            $to_delete =~ s/TRADE KO //;
            if(! $world->exists_treaty_by_type($self->name, $to_delete, 'commercial'))
            {
                return "DELETE TRADEROUTE " . $self->name . "->" . $to_delete;
            }
        }
    }
    else
    {
        my @remains = $self->get_events("REMAIN", $prev_year);
        my @deleted = $self->get_events("TRADEROUTE DELETED", $prev_year);
        my @boost = $self->get_events("BOOST OF PRODUCTION", $prev_year);
        if(@remains > 0 && @deleted == 0 && @boost == 0)
        {
            my $rem = $remains[0];
            $rem =~ m/^REMAIN (.*)$/;
            my $remaining = $1;
            if($remaining >= TRADING_QUOTE && $self->production_for_export > TRADEROUTE_COST)
            {
                return "ADD ROUTE";
            }
        }
    }
    if($self->production_for_export >= ECONOMIC_AID_COST)
    {
        my @hates = $world->get_hates($self->name);
        if(@hates)
        {
            #Minor hate is used
            @hates = sort { $b->factor <=> $a->factor } @hates;
            my $other = $hates[0]->destination($self->name);
            return "ECONOMIC AID FOR $other";
        }
    }
    return undef;
}

### MILITARY ###
# Orders:
#   DECLARE WAR TO
#   MILITARY SUPPORT
#   RECALL MILITARY SUPPORT
#   BUILD TROOPS
#   AID INSURGENTS
sub military_advisor
{
    my $self = shift;
    my $world = shift;
    if(! $world->war_busy($self->name))
    {
        #WAR ATTEMPT
        my @crises = $world->get_crises($self->name);
        if(@crises > 0)
        {
            foreach my $c ($world->shuffle("Mixing crisis for war for " . $self->name, @crises))
            {
                my $enemy = $world->get_nation($c->destination($self->name));
                next if $world->war_busy($enemy->name);
                if($world->in_military_range($self->name, $enemy->name))
                {
                    if($self->good_prey($enemy, $world, $c->crisis_level))
                    {
                        return "DECLARE WAR TO " . $enemy->name;
                    }
                    else
                    {
                        if($self->production_for_export >= AID_INSURGENTS_COST)
                        {
                            return "AID INSURGENTS IN " . $enemy->name;
                        }
                    }
                }
                else
                {
                    if($self->army >= MIN_ARMY_TO_EXPORT)
                    {
                        my @friends = $world->get_friends($self->name);                        
                        for(@friends)
                        {
                            if($world->border_exists($_, $enemy->name))
                            {
                                return "MILITARY SUPPORT " . $_;
                            }
                        }
                    }
                }
            }
        }
        #MILITARY SUPPORT
        if($self->army >= MIN_ARMY_TO_EXPORT)
        {
            #FOR REBELS
            my @enemies = $world->shuffle("Choosing enemy for rebel support for " . $self->name, $world->get_hates($self->name)); 
            foreach my $e (@enemies)
            {
                if($world->at_civil_war($e))
                {
                    return "REBEL MILITARY SUPPORT " . $e;
                }
            }
            #FOR A NATION
            my @friends = $world->shuffle("Choosing friend to support for " . $self->name, $world->get_friends($self->name));
            my $f = $friends[0];
            if($world->get_nation($f)->accept_military_support($self->name, $world))
            {
                return "MILITARY SUPPORT " . $f;
            }
        }
    }
    if($self->army <= ARMY_TO_RECALL_SUPPORT)
    {
        my @supports = $world->supporter($self->name);
        if(@supports > 0)
        {
            @supports = $world->shuffle("Choosing support to recall", @supports);
            return "RECALL MILITARY SUPPORT " . $supports[0]->destination($self->name);
        }
    }
    if($self->army < MAX_ARMY_FOR_SIZE->[ $self->size ])
    {
        if($self->army < MINIMUM_ARMY_LIMIT)
        {
            return "BUILD TROOPS";
        }
        elsif($self->army < MEDIUM_ARMY_LIMIT)
        {
            if($self->production_for_export > MEDIUM_ARMY_BUDGET)
            {
                return "BUILD TROOPS";
            }
        }
        else
        {
            if($self->production_for_export > MAX_ARMY_BUDGET)
            {
                return "BUILD TROOPS";
            }
        }
    }
}
sub accept_military_support
{
    my $self = shift;
    my $other = shift;
    my $world = shift;
    return 0 if($world->already_in_military_support($self->name));
    return $self->army < ARMY_TO_ACCEPT_MILITARY_SUPPORT;
}

sub good_prey
{
    my $self = shift;
    my $enemy = shift;
    my $world = shift;
    my $level = shift;
    if($self->army < MIN_ARMY_FOR_WAR)
    {
        return 0;
    }
    my $war_points = 0;

    #ARMY EVALUATION
    my $army_ratio;
    if($enemy->army > 0)
    {
        $army_ratio = int($self->army / $enemy->army);
    }
    else
    {
        $army_ratio = 3;
    }
    if($army_ratio < 1)
    {
        my $reverse_army_ratio = $enemy->army / $self->army;
        if($reverse_army_ratio > MIN_INFERIOR_ARMY_RATIO_FOR_WAR)
        {
            return 0;
        }
        else
        {
            $army_ratio = -1;
        }
    }
    $war_points += $army_ratio;

    #INTERNAL EVALUATION
    if($self->internal_disorder_status eq 'Peace')
    {
        $war_points += 1;
    }
    elsif($self->internal_disorder_status eq 'Terrorism')
    {
        $war_points += 0;
    }
    elsif($self->internal_disorder_status eq 'Insurgence')
    {
        $war_points += -1;
    }

    #WEALTH EVALUATION
    my $wealth = $world->get_statistics_value(prev_turn($self->current_year), $self->name, 'wealth');
    my $enemy_wealth = $world->get_statistics_value(prev_turn($self->current_year), $enemy->name, 'wealth');
    if($wealth && $enemy_wealth)
    {
        $war_points += 1 if($enemy_wealth > $wealth);
    }
    else
    {
        $war_points += 1;
    }

                    
    #COALITION EVALUATION
    if($world->empire($self->name) && $world->empire($enemy->name) && $world->empire($self->name) > $world->empire($enemy->name))
    {
        $war_points += 1;
    }

    if($war_points + $level >= 4)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

1;

