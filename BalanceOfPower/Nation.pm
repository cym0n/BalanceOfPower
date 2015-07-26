package BalanceOfPower::Nation;

use strict;
use v5.10;

use Moo;
use BalanceOfPower::Utils qw( prev_year next_year );
use BalanceOfPower::Constants ':all';
use List::Util qw(shuffle);

has name => (
    is => 'ro',
    default => 'Dummyland'
);
has export_quote => (
    is => 'ro',
    default => 50
);

has government_strength => (
    is => 'rw',
    default => 70
);

has situation => (
    is => 'rw',
    default => sub { { status => 'free' } }
);
has internal_disorder => (
    is => 'rw',
    default => 0
);
has production_for_domestic => (
    is => 'rw',
    default => 0
);
has production_for_export => (
    is => 'rw',
    default => 0
);
has wealth => (
    is => 'rw',
    default => 0
);
has debt => (
    is => 'rw',
    default => 0
);
has civil_war => (
    is => 'rw',
    default => 0
);
has at_war => (
    is => 'rw',
    default => 0
);
has current_year => (
    is => 'rw'
);

has events => (
    is => 'rw',
);

has army => (
    default => 0,
    is => 'rw'
);

sub production
{
    my $self = shift;
    my $prod = shift;
    if($prod)
    {
        if($prod <= DEBT_TO_RAISE_LIMIT && $self->debt < MAX_DEBT && DEBT_ALLOWED)
        {
            $prod += PRODUCTION_THROUGH_DEBT;
            $self->debt($self->debt + 1);
            $self->register_event("DEBT RISE");
        }
        my $internal = $prod - (($self->export_quote * $prod) / 100);
        my $export = $prod - $internal;
        $self->production_for_domestic($internal);
        $self->production_for_export($export);
    }
    return $self->production_for_domestic + $self->production_for_export;
}

sub calculate_internal_wealth
{
    my $self = shift;
    my $internal_production = $self->production_for_domestic();
    $self->add_wealth($internal_production * INTERNAL_PRODUCTION_GAIN);
    $self->production_for_domestic(0);
    $self->register_event("INTERNAL " . $internal_production);
}
sub calculate_trading
{
    my $self = shift;
    my $world = shift;
    my @routes = $world->routes_for_node($self->name);
    my %diplomacy = $world->diplomacy_for_node($self->name);
    @routes = sort { $b->factor_for_node($self->name) * 1000 + $diplomacy{$b->destination($self->name)}
                     <=>
                     $a->factor_for_node($self->name) * 1000 + $diplomacy{$a->destination($self->name)}
                   } @routes;
    if(@routes > 0)
    {
        foreach my $r (@routes)
        {
           if($self->production_for_export >= TRADING_QUOTE)
           {
                $self->trade(TRADING_QUOTE, $r->factor_for_node($self->name));
                $self->register_event("TRADE OK " . $r->destination($self->name) . " [x" . $r->factor_for_node($self->name) . "]");
           }
           else
           {
                $self->trade(0, $r->factor_for_node($self->name));
                $self->register_event("TRADE KO " . $r->destination($self->name));
           }     
        }
    }
}
sub convert_remains
{
    my $self = shift;
    $self->add_wealth($self->production);
    $self->register_event("REMAIN " . $self->production);
    $self->production_for_domestic(0);
    $self->production_for_export(0);
}
sub war_cost
{
    my $self = shift;
    if($self->at_war)
    {
        $self->add_wealth(-1 * WAR_WEALTH_MALUS);
        $self->register_event("WAR COST PAYED: " . WAR_WEALTH_MALUS);
    }
}


sub trade
{
    my $self = shift;
    my $production = shift;
    my $gain = shift;
    $self->subtract_production('export', $production);
    $self->add_wealth($production * $gain);
    $self->add_wealth(-1 * TRADINGROUTE_COST);
}
sub calculate_disorder
{
    my $self = shift;
    return if($self->internal_disorder_status eq 'Civil war');
    my $disorder = 0;
    my $actual_poverty_limit = POVERTY_LIMIT - int(($self->internal_disorder + 1) / INTERNAL_DISORDER_VARIATION_FACTOR);
    my $actual_richness_limit = RICHNESS_LIMIT - int(($self->internal_disorder + 1) / INTERNAL_DISORDER_VARIATION_FACTOR);
    if($self->wealth < $actual_poverty_limit)
    {
        $disorder = int(($actual_poverty_limit - $self->wealth) / int($self->government_strength / 10));
    }
    elsif($self->wealth > $actual_richness_limit)
    {
        $disorder = -1 * int((($self->wealth - $actual_richness_limit) * $self->government_strength) / 100);
    }
    $self->add_internal_disorder($disorder);
}
sub decision
{
    my $self = shift;
    my $world = shift;
    return undef if($self->internal_disorder_status eq 'Civil war');
    my @advisors;
    if($self->at_war)
    {
        @advisors = ('military');
    }
    else
    {
        @advisors = ('domestic', 'economy', 'military');
        shuffle @advisors;
    }
    foreach my $a (@advisors)
    {
        my $decision = undef;
        if($a eq 'domestic')
        {
            $decision = $self->domestic_advisor();
        }
        elsif($a eq 'economy')
        {
            $decision = $self->economy_advisor();
        }
        elsif($a eq 'military')
        {
            $decision = $self->military_advisor($world);
        }
        return $decision if($decision);
    }
    return undef;
}

sub military_advisor
{
    my $self = shift;
    my $world = shift;
    if($self->army >= MIN_ARMY_FOR_WAR && ! $self->at_war)
    {
        my @crises = $world->get_crises($self->name);
        if(@crises > 0)
        {
            foreach my $c (@crises)
            {
                if($world->border_exists($c->node1, $c->node2))
                {
                    my $war_points = 0;
                    my $enemy = $world->get_nation($c->destination($self->name));
                    next if($enemy->at_war);

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
                            last;
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
                    my $wealth = $world->get_statistics_value(prev_year($self->current_year), $self->name, 'wealth');
                    my $enemy_wealth = $world->get_statistics_value(prev_year($self->current_year), $enemy->name, 'wealth');
                    $war_points += 1 if($enemy_wealth > $wealth);

                    if($war_points + $c->factor >= 4)
                    {
                        return $self->name . ": DECLARE WAR TO " . $enemy->name;
                    }
                }
            }
        }
    }
    if($self->army < MINIMUM_ARMY_LIMIT)
    {
        return $self->name . ": BUILD TROOPS";
    }
    elsif($self->army < MEDIUM_ARMY_LIMIT)
    {
        if($self->production_for_export > MEDIUM_ARMY_BUDGET)
        {
            return $self->name . ": BUILD TROOPS";
        }
    }
    elsif($self->army < MAX_ARMY_LIMIT)
    {
        if($self->production_for_export > MAX_ARMY_BUDGET)
        {
            return $self->name . ": BUILD TROOPS";
        }
    }
}


sub domestic_advisor
{
    my $self = shift;
    if($self->internal_disorder > WORRYING_LIMIT && $self->production_for_domestic > DOMESTIC_BUDGET)
    {
        return $self->name . ": LOWER DISORDER";
    }
    else
    {
        return undef;
    }
}
sub economy_advisor
{
    my $self = shift;
    my $prev_year = prev_year($self->current_year);
    my @trade_ko = $self->get_events("TRADE KO", $prev_year);
    if(@trade_ko > 1)
    {
        my $to_delete = $trade_ko[$#trade_ko];
        $to_delete =~ s/TRADE KO //;
        return $self->name . ": DELETE TRADEROUTE " . $self->name . "->" . $to_delete;
    }
    elsif(@trade_ko == 1)
    {
        my @older_trade_ko = $self->get_events("TRADE KO", prev_year($prev_year));
        if(@older_trade_ko > 0)
        {
            my $to_delete = $trade_ko[$#trade_ko];
            $to_delete =~ s/TRADE KO //;
            return $self->name . ": DELETE TRADEROUTE " . $self->name . "->" . $to_delete;
        }
    }
    else
    {
        my @remains = $self->get_events("REMAIN", $prev_year);
        my @deleted = $self->get_events("TRADEROUTE DELETED", $prev_year);
        if(@remains > 0 && @deleted == 0)
        {
            my $rem = $remains[0];
            $rem =~ m/^REMAIN (.*)$/;
            my $remaining = $1;
            if($remaining >= TRADING_QUOTE && $self->production_for_export > TRADINGROUTE_COST)
            {
                return $self->name . ": ADD ROUTE";
            }
        }
    }
    return undef;
}

sub subtract_production
{
    my $self = shift;
    my $which = shift;
    my $production = shift;
    if($which eq 'export')
    {
        $self->production_for_export($self->production_for_export - $production);
    }
    elsif($which eq 'domestic')
    {
        $self->production_for_domestic($self->production_for_domestic - $production);
    }
    
}
sub add_wealth
{
    my $self = shift;
    my $wealth = shift;
    $self->wealth($self->wealth + $wealth);
    $self->wealth(0) if($self->wealth < 0);
}
sub lower_disorder
{
    my $self = shift;
    if($self->production_for_domestic > RESOURCES_FOR_DISORDER)
    {
        $self->subtract_production('domestic', RESOURCES_FOR_DISORDER);
        $self->add_internal_disorder(-1 * DISORDER_REDUCTION);
        $self->register_event("DISORDER LOWERED TO " . $self->internal_disorder);
    }
}


sub add_internal_disorder
{
    my $self = shift;
    my $disorder = shift;
    my $actual_disorder = $self->internal_disorder_status;
    $self->internal_disorder($self->internal_disorder + $disorder);
    if($self->internal_disorder > 100)
    {
        $self->internal_disorder(100);
    }
    if($self->internal_disorder < 0)
    {
        $self->internal_disorder(0);
    }
    my $new_disorder = $self->internal_disorder_status;
    if($actual_disorder ne $new_disorder)
    {
        $self->register_event("INTERNAL DISORDER LEVEL FROM $actual_disorder TO $new_disorder");
        if($new_disorder eq "Civil war")
        {
            $self->register_event("CIVIL WAR OUTBREAK");
            $self->civil_war(0);
        }
    }
}
sub internal_disorder_status
{
    my $self = shift;
    my $disorder = $self->internal_disorder;
    if($disorder < INTERNAL_DISORDER_TERRORISM_LIMIT)
    {
        return "Peace";
    }
    elsif($disorder < INTERNAL_DISORDER_INSURGENCE_LIMIT)
    {
        return "Terrorism";
    }
    elsif($disorder < INTERNAL_DISORDER_CIVIL_WAR_LIMIT)
    {
        return "Insurgence";
    }
    else
    {
        return "Civil war";
    }
}
sub fight_civil_war
{
    my $self = shift;
    my $government = shift;
    my $rebels = shift;
    $self->register_event("FIGHTING CIVIL WAR");
    if($self->army >= ARMY_UNIT_FOR_INTERNAL_DISORDER)
    {
        $self->add_army(-1 * ARMY_UNIT_FOR_INTERNAL_DISORDER);
        $government += ARMY_HELP_FOR_INTERNAL_DISORDER;
    }
    if($government > $rebels)
    {
        return $self->civil_war_battle('government');
    }
    elsif($rebels > $government)
    {
        return $self->civil_war_battle('rebels');
    }
    else
    {
        return undef;
    }
}
sub civil_war_battle
{
    my $self = shift;
    my $battle_winner = shift;
    if($battle_winner eq 'government')
    {
        if($self->civil_war > 0)
        {
            $self->civil_war($self->civil_war + 1);
            if($self->civil_war >= CIVIL_WAR_WIN)
            {
                $self->internal_disorder(AFTER_CIVIL_WAR_INTERNAL_DISORDER);
                $self->register_event("THE GOVERNMENT WON THE CIVIL WAR");
                $self->civil_war(0);
                return 'government';
            }
        }
        elsif($self->civil_war <= 0)
        {
            $self->civil_war(1);
        }
    }
    elsif($battle_winner eq 'rebels')
    {
        if($self->civil_war < 0)
        {
            $self->civil_war($self->civil_war - 1);
            if(abs($self->civil_war) >= CIVIL_WAR_WIN)
            {
                $self->internal_disorder(AFTER_CIVIL_WAR_INTERNAL_DISORDER);
                $self->register_event("THE REBELS WON THE CIVIL WAR");
                $self->civil_war(0);
                return 'rebels';
            }
        }
        elsif($self->civil_war >= 0)
        {
            $self->civil_war(-1);
        }
    }
    return undef;
}

sub new_government
{
    my $self = shift;
    my $params = shift;
    $self->government_strength($params->{'government_strength'});
    $self->register_event("NEW GOVERNMENT CREATED");
}

sub build_troops
{
    my $self = shift;
    if($self->production_for_export > ARMY_COST)
    {
        $self->subtract_production('export', ARMY_COST);
        $self->add_army(ARMY_UNIT);
        $self->register_event("NEW TROOPS FOR THE ARMY");
    } 
}
sub add_army
{
    my $self = shift;
    my $army = shift;
    $self->army($self->army + $army);
}
sub situation_clock
{
    my $self = shift;
    my $situation = $self->situation;
    if(exists $situation->{clock})
    {
        $situation->{clock} = $situation->{clock} + 1;
    }
    if($situation->{clock} == CONQUEST_CLOCK_LIMIT && $situation->{status} eq 'conquered')
    {
        $situation->{clock} = 0;
        $situation->{status} = 'under control';
        $self->register_event("UNDER CONTROL OF " . $situation->{'by'});
    }
    $self->situation($situation);
}





sub print
{
    my $self = shift;
    my $out = "";
    $out .= "Name: " . $self->name . "\n";
    $out .= "Export quote: " . $self->export_quote . "\n";
    $out .= "Government strength: " . $self->government_strength . "\n";
    $out .= "Events:\n";
    foreach my $year (sort keys %{$self->events})
    {
        $out .= "  $year:\n";
        foreach my $e (@{$self->events->{$year}})
        {
            $out .= "    " . $e ."\n";
        }
    }
    return $out;
}


sub register_event
{
    my $self = shift;
    my $event = shift;
    $self->events({}) if(! $self->events );
    push @{$self->events->{$self->current_year}}, $event;
}
sub get_events
{
    my $self = shift;
    my $label = shift;
    my $year = shift;
    if($self->events && exists $self->events->{$year})
    {
        my @events = grep { $_ =~ /^$label/ } @{$self->events->{$year}};
        return @events;
    }
    else
    {
        return ();
    }
}


1;
