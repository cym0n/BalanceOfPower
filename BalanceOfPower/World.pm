package BalanceOfPower::World;

use strict;
use v5.10;

use Moo;
use List::Util qw(shuffle);

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw(prev_year next_year random random10 get_year_turns);
use BalanceOfPower::Nation;
use BalanceOfPower::TradeRoute;
use BalanceOfPower::Friendship;

has current_year => (
    is => 'rw'
);
has nations => (
    is => 'rw',
    default => sub { [] }
);



with 'BalanceOfPower::Role::Historian';
with 'BalanceOfPower::Role::Diplomat';
with 'BalanceOfPower::Role::Merchant';
with 'BalanceOfPower::Role::Mapmaker';
with 'BalanceOfPower::Role::Warlord';


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

sub print_nation
{
    my $self = shift;
    my $n = $self->get_nation( shift );
    return $n->print;
}



#Initial values, randomly generated
sub init_random
{
    my $self = shift;
    my @nations = @_;

    $self->load_borders();

    my %routes_counter;
    foreach my $n (@nations)
    {
        say "Working on $n";
        my $export_quote = random10(MIN_EXPORT_QUOTE, MAX_EXPORT_QUOTE);
        say "  export quote: $export_quote";
        my $government_strength = random10(MIN_GOVERNMENT_STRENGTH, MAX_GOVERNMENT_STRENGTH);
        say "  government strength: $government_strength";
        push @{$self->nations}, BalanceOfPower::Nation->new( name => $n, export_quote => $export_quote, government_strength => $government_strength);
        $routes_counter{$n} = 0 if(! exists $routes_counter{$n});
        my $how_many_routes = random(MIN_STARTING_TRADEROUTES, MAX_STARTING_TRADEROUTES);
        say "  routes to generate: $how_many_routes [" . $routes_counter{$n} . "]";
        my @my_names = @nations;
        @my_names = grep { $_ ne $n } @my_names;
        while($routes_counter{$n} < $how_many_routes)
        {
            my $second_node = $my_names[rand @my_names];
            if($second_node ne $n && ! $self->route_exists($n, $second_node))
            {
                say "  creating trade route to $second_node";
                @my_names = grep { $_ ne $second_node } @my_names;
                $self->generate_traderoute($n, $second_node, 0);
                $routes_counter{$n}++;
                $routes_counter{$second_node} = 0 if(! exists $routes_counter{$second_node});
                $routes_counter{$second_node}++;
            }
        }
        foreach my $n2 (@nations)
        {
            if($n ne $n2 && ! $self->diplomacy_exists($n, $n2))
            {
                my $rel = new BalanceOfPower::Friendship( node1 => $n,
                                                          node2 => $n2,
                                                          factor => random(0,100));
                push @{$self->diplomatic_relations}, $rel;
            }
        }
    }
}

# Configure current year
# Give production to countries. Countries split it between export and domestic and, if allowed, raise the debt in case of necessity
# Wealth reset
# Production and debt recorded
sub init_year
{
    my $self = shift;
    my $turn = shift;
    $self->current_year($turn);
    foreach my $n (@{$self->nations})
    {
        $n->current_year($turn);
        $n->wealth(0);
        my $prod = $self->calculate_production($n);
        $n->production($prod);
        $self->set_statistics_value($n, 'production', $prod);
        $self->set_statistics_value($n, 'debt', $n->debt);
    }
}



# PRODUCTION MANAGEMENT ###############################

#Say the value of starting production used to calculate production for a turn.
#Usually is just the value of production the turn before, but if rebels won a civil war it has to be undef to allow a totally random generation of production.
sub get_base_production
{
    my $self = shift;
    my $nation = shift;
    my $statistics_production = $self->get_statistics_value(prev_year($nation->current_year), $nation->name, 'production'); 
    if($statistics_production)
    {
        my @newgov = $nation->get_events("NEW GOVERNMENT CREATED", prev_year($nation->current_year));
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
    if($production)
    {
        $next = $production + random10(MIN_DELTA_PRODUCTION, MAX_DELTA_PRODUCTION);
    }
    else
    {
        $next = random10(MIN_STARTING_PRODUCTION, MAX_STARTING_PRODUCTION);
    }
    my @retreats = $n->get_events("RETREAT FROM", prev_year($n->current_year));
    if(@retreats > 0)
    {
        $next -= ATTACK_FAILED_PRODUCTION_MALUS;
    }

    if($next < 0)
    {
        $next = 0;
    }
    return $next;
}


#Conquered nations give to the conqueror a quote of their production at start of the turn
sub war_debts
{
    my $self = shift;
    foreach my $n (@{$self->nations})
    {
        if($n->situation->{status} eq 'conquered')
        {
            my $receiver = $self->get_nation($n->situation->{by});
            my $amount_domestic = $n->production_for_domestic >= CONQUEROR_LOOT_BY_TYPE ? CONQUEROR_LOOT_BY_TYPE : $n->production_for_domestic;
            my $amount_export = $n->production_for_export >= CONQUEROR_LOOT_BY_TYPE ? CONQUEROR_LOOT_BY_TYPE : $n->production_for_export;
            $n->subtract_production('domestic', $amount_domestic);
            $n->subtract_production('export', $amount_export);
            $n->register_event("LOOTED BY " . $receiver->name . ": $amount_domestic + $amount_export");
            $receiver->subtract_production('domestic', -1 * $amount_domestic);
            $receiver->subtract_production('export', -1 * $amount_export);
            $receiver->register_event("LOOTED FROM " . $n->name . ": $amount_domestic + $amount_export");
            $n->situation_clock();
        }
    }
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
            if(! $attacker->at_war && ! $defender->at_war)
            {
                $attacker->at_war(1);
                $defender->at_war(1); 
                $self->register_event("CRISIS BETWEEN " . $attacker->name . " AND " . $defender->name . " BECAME WAR"); 
                $self->create_war($attacker->name, $defender->name);
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
                    $self->register_event("TRADEROUTE CREATION FAILED FOR LACK OF PARTNERS", $node1);
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
                        $self->register_event("TRADEROUTE CREATION FAILED FOR LACK OF PARTNERS", $node1);
                    }
                }
            }
            else
            {
                $self->register_event("TRADEROUTE CREATION NOT POSSIBLE", $node1);
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
            say $decision;
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
        $n->war_cost();
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
                $self->free_nation($n);
            }
        }
        if($n->at_war() && $n->internal_disorder_status eq 'Civil war')
        {
            say "CIVIL WAR DURING WAR SITUATION!";
            #This should happen only if status changed during this iteration
            my $war = $self->get_war($n->name);
            my $attacker = $self->get_nation( $war->node1 );
            my $defender = $self->get_nation( $war->node2 );
            my $winner = "";
            if($attacker->name eq $n->name)
            {
                $winner = 'defender-civilwar';
            }
            elsif($defender->name eq $n->name)
            {
                $winner = 'attacker-civilwar';
            }
            $self->end_war($attacker, $defender, $winner);
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



1;
