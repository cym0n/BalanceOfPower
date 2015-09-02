package BalanceOfPower::World;

use strict;
use v5.10;

use Moo;
use List::Util qw(shuffle);

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw(prev_turn random random10);
use BalanceOfPower::Nation;

has name => (
    is => 'ro',
    default => 'WORLD'
);
has first_year => (
    is => 'ro'
);
has current_year => (
    is => 'rw'
);
has nations => (
    is => 'rw',
    default => sub { [] }
);
has nation_names => (
    is => 'rw',
    default => sub { [] }
);


with 'BalanceOfPower::Role::Player';
with 'BalanceOfPower::Role::Herald';
with 'BalanceOfPower::Role::Diplomat';
with 'BalanceOfPower::Role::Merchant';
with 'BalanceOfPower::Role::Ruler';
with 'BalanceOfPower::Role::Mapmaker';
with 'BalanceOfPower::Role::Warlord';
with 'BalanceOfPower::Role::Historian';

sub get_nation
{
    my $self = shift;
    my $nation = shift;
    my @nations = grep { $_->name eq $nation } @{$self->nations};
    if(@nations > 0)
    {
        return $nations[0];
    }
    else
    {
        return undef;
    }
}

#Initial values, randomly generated
sub init_random
{
    my $self = shift;
    my @nations = @_;

    $self->nation_names = \@nations;

    $self->load_borders();

    foreach my $n (@nations)
    {
        say "Working on $n";
        my $export_quote = random10(MIN_EXPORT_QUOTE, MAX_EXPORT_QUOTE);
        say "  export quote: $export_quote";
        my $government_strength = random10(MIN_GOVERNMENT_STRENGTH, MAX_GOVERNMENT_STRENGTH);
        say "  government strength: $government_strength";
        push @{$self->nations}, BalanceOfPower::Nation->new( name => $n, export_quote => $export_quote, government_strength => $government_strength);
    }
    $self->init_trades();
    $self->init_diplomacy();
}

# Configure current year
# Give production to countries. Countries split it between export and domestic and, if allowed, raise the debt in case of necessity
# Wealth reset
# Production and debt recorded
sub init_year
{
    my $self = shift;
    my $turn = shift;
    say $turn;
    $self->current_year($turn);
    foreach my $n (@{$self->nations})
    {
        print ".";
        $n->current_year($turn);
        $n->wealth(0);
        my $prod = $self->calculate_production($n);
        $n->production($prod);
        $self->set_statistics_value($n, 'production', $prod);
        $self->set_statistics_value($n, 'debt', $n->debt);
    }
    print "\n";
}



# PRODUCTION MANAGEMENT ###############################

#Say the value of starting production used to calculate production for a turn.
#Usually is just the value of production the turn before, but if rebels won a civil war it has to be undef to allow a totally random generation of production.
sub get_base_production
{
    my $self = shift;
    my $nation = shift;
    my $statistics_production = $self->get_statistics_value(prev_turn($nation->current_year), $nation->name, 'production'); 
    if($statistics_production)
    {
        my @newgov = $nation->get_events("NEW GOVERNMENT CREATED", prev_turn($nation->current_year));
        if(@newgov > 0)
        {
            return undef;
        }
        else
        {
            return $statistics_production;
        }
    }
    else
    {
        return undef;
    }
}
sub calculate_production
{
    my $self = shift;
    my $n = shift;
    my $production = $self->get_base_production($n);
    my $next = 0;
    if(defined $production)
    {
        $next = $production + random10(MIN_DELTA_PRODUCTION, MAX_DELTA_PRODUCTION);
    }
    else
    {
        $next = random10(MIN_STARTING_PRODUCTION, MAX_STARTING_PRODUCTION);
    }
    my @retreats = $n->get_events("RETREAT FROM", prev_turn($n->current_year));
    if(@retreats > 0)
    {
        $next -= ATTACK_FAILED_PRODUCTION_MALUS;
        $self->send_event("COST FOR DEFEAT ON PRODUCTION: " . ATTACK_FAILED_PRODUCTION_MALUS);
    }

    if($next < 0)
    {
        $next = 0;
    }
    if($next > MAX_PRODUCTION)
    {
        $next = MAX_PRODUCTION;
    }
    return $next;
}


#Conquered nations give to the conqueror a quote of their production at start of the turn
sub war_debts
{
    my $self = shift;
    for(@{$self->influences})
    {
        $self->loot($_);
    }
    $self->situation_clock();
}

sub loot
{
    my $self = shift;
    my $influence = shift;
    my $n2 = $influence->node2;
    my $n1 = $influence->node1;
    my $quote = $influence->get_loot_quote();
    return if(! $quote || $quote == 0);
    my $nation = $self->get_nation($n2);
    my $receiver = $self->get_nation($n1);
    my $amount_domestic = $nation->production_for_domestic >= $quote ? $quote : $nation->production_for_domestic;
    my $amount_export = $nation->production_for_export >= $quote ? $quote : $nation->production_for_export;
    $nation->subtract_production('domestic', $amount_domestic);
    $nation->subtract_production('export', $amount_export);
    $nation->register_event("PAY LOOT TO " . $receiver->name . ": $amount_domestic + $amount_export");
    $receiver->subtract_production('domestic', -1 * $amount_domestic);
    $receiver->subtract_production('export', -1 * $amount_export);
    $receiver->register_event("ACQUIRE LOOT FROM " . $nation->name . ": $amount_domestic + $amount_export");
}



# PRODUCTION MANAGEMENT END ###############################################

# DECISIONS ###############################################################

# Decisions are collected and executed
sub execute_decisions
{   
    my $self = shift;
    my @decisions = $self->decisions();
    my @route_adders = ();
    foreach my $d (@decisions)
    {
        if($d =~ /^(.*): DELETE TRADEROUTE (.*)->(.*)$/)
        {
            $self->delete_route($2, $3);
        }
        elsif($d =~ /^(.*): ADD ROUTE$/)
        {
            push @route_adders, $1;
        }
        elsif($d =~ /^(.*): LOWER DISORDER$/)
        {
           my $nation = $self->get_nation($1);
           $nation->lower_disorder();
        }
        elsif($d =~ /^(.*): BUILD TROOPS$/)
        {
           my $nation = $self->get_nation($1);
           $nation->build_troops();
        }
        elsif($d =~ /^(.*): DECLARE WAR TO (.*)$/)
        {
            my $attacker = $self->get_nation($1);
            my $defender = $self->get_nation($2);
            if(! $self->at_war($attacker->name) && ! $self->at_war($defender->name))
            {
                $self->create_war($attacker, $defender);
            }
        }
        


    }
    $self->manage_route_adding(@route_adders);
}

sub manage_route_adding
{
    my $self = shift;
    my @route_adders = @_;
    if(@route_adders > 1)
    {
       @route_adders = shuffle @route_adders; 
       my $done = 0;
       while(! $done)
       {
            my $node1 = shift @route_adders;
            if($self->suitable_route_creator($node1))
            {
                if(@route_adders == 0)
                {
                    $self->broadcast_event("TRADEROUTE CREATION FAILED FOR LACK OF PARTNERS", $node1);
                    $done = 1;
                } 
                else
                {
                    my $complete = 0;
                    foreach my $second (@route_adders)
                    {
                        if($self->suitable_new_route($node1, $second))
                        {
                            @route_adders = grep { $_ ne $second } @route_adders;
                            $self->generate_traderoute($node1, $second, 1);
                            $complete = 1;
                        }
                        last if $complete;
                    }     
                    if($complete == 0)
                    {
                        $self->broadcast_event("TRADEROUTE CREATION FAILED FOR LACK OF PARTNERS", $node1);
                    }
                }
            }
            else
            {
                $self->broadcast_event("TRADEROUTE CREATION NOT POSSIBLE", $node1);
            }
            $done = 1 if(@route_adders == 0);
       }
    }
}
sub decisions
{
    my $self = shift;
    my @decisions = ();
    foreach my $nation (@{$self->nations})
    {
        my $decision = $nation->decision($self);
        if($decision)
        {
            push @decisions, $decision;
        }
    }
    return @decisions;
}

# DECISIONS END ###########################################################

# ECONOMY #################################################################

# Calculate internal wealth converting domestic production to wealth
# Active trade routes one by one trying to generate wealth from each of them
# Convert remain as generating internal wealth
sub economy
{
    my $self = shift;
    foreach my $n (@{$self->nations})
    {
        $n->calculate_internal_wealth();
        $n->calculate_trading($self);
        $n->convert_remains();
        if($self->at_war($n->name))
        {
            $n->war_cost();
        }
        $self->set_statistics_value($n, 'wealth', $n->wealth);
    }
}

# ECONOMY END #############################################################

# INTERNAL DISORDER #######################################################

# If Peace internal disorder variation is only based on wealth
# If Terrorism or Insurgence internal disorder variation is base on wealth and a random factor
# If Civil war internal disorder IS NOT calculated. Civil war is fought.
sub internal_conflict
{
    my $self = shift;
    foreach my $n (@{$self->nations})
    {
        my $present_status = $n->internal_disorder_status;
        if($n->internal_disorder_status eq 'Peace')
        {
            $n->calculate_disorder();
        }
        elsif($n->internal_disorder_status eq 'Terrorism' || $n->internal_disorder_status eq 'Insurgence' )
        {
            $n->add_internal_disorder(random(-1 * INTERNAL_DISORDER_VARIATION_FACTOR, INTERNAL_DISORDER_VARIATION_FACTOR));
            $n->calculate_disorder();
        }
        elsif($n->internal_disorder_status eq 'Civil war')
        {
            my $winner = $n->fight_civil_war(random(0, 100), random(0, 100));
            if($winner && $winner eq 'rebels')
            {
                $n->new_government({ government_strength => random10(MIN_GOVERNMENT_STRENGTH, MAX_GOVERNMENT_STRENGTH)});
                $self->free_nation($n->name);
            }
        }
        if($n->internal_disorder_status eq 'Civil war' && $present_status ne 'Civil war')
        {
            #This should happen only if status changed during this iteration
            $self->lose_war($n->name, 1);
        }
        $self->set_statistics_value($n, 'internal disorder', $n->internal_disorder);
    }
}

# INTERNAL DISORDER END ######################################################

# WAR ######################################################################

sub warfare
{
    my $self = shift;
    $self->fight_wars();
    foreach my $n (@{$self->nations})
    {
        $self->set_statistics_value($n, 'army', $n->army);    
    }    
}
# WAR END ##################################################################

sub register_global_data
{
    my $self = shift;
    my $crises = @{$self->crises};
    my $wars = @{$self->wars};
    $self->set_statistics_value(undef, 'crises', $crises);
    $self->set_statistics_value(undef, 'wars', $wars);
}

sub collect_events
{
    my $self = shift;
    my @events_to_collect = ("DISORDER LOWERED TO",
                             "INTERNAL DISORDER LEVEL FROM",
                             "CIVIL WAR OUTBREAK",
                             "THE GOVERNMENT WON THE CIVIL WAR",
                             "THE REBELS WON THE CIVIL WAR",
                             "NEW GOVERNMENT CREATED");
   foreach my $n (@{$self->nations})
   {
       my @collected = ();
       foreach my $e (@events_to_collect)
       {
            push @collected, $n->get_events($e, $self->current_year);
       }
       foreach my $c (@collected)
       {
            $self->register_event($n->name . ": ". $c);
       }
       
   }
}



1;
