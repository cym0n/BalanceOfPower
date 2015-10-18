package BalanceOfPower::World;

use strict;
use v5.10;

use Moo;
use Data::Dumper;
use Cwd 'abs_path';

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw(prev_turn next_turn);
use BalanceOfPower::Nation;
use BalanceOfPower::Dice;
use BalanceOfPower::Commands;

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
has order => (
    is => 'rw',
    default => ""
);
has autoplay => (
    is => 'rw',
    default => 0
);
has data_directory => (
    is => 'rw',
    default => sub {
        my $module_file_path = __FILE__;
        my $root_path = abs_path($module_file_path);
        $root_path =~ s/World\.pm//;
        say $root_path . "data"; 
        my $data_directory = $root_path . "data";

    }
);
has dice => (
    is => 'ro',
    default => sub { BalanceOfPower::Dice->new( log_name => "bop-dice.log" ) },
    handles => { random => 'random',
                 random10 => 'random10',
                 random_around_zero => 'random_around_zero',
                 shuffle => 'shuffle_array',
                 tricks => 'tricks',
                 forced_advisor => 'forced_advisor',
                 only_one_nation_acting => 'only_one_nation_acting',
                 dice_log => 'log_active'
               }
);


with 'BalanceOfPower::Role::Player';
with 'BalanceOfPower::Role::Herald';
with 'BalanceOfPower::Role::Ruler';
with 'BalanceOfPower::Role::Mapmaker';
with 'BalanceOfPower::Role::Diplomat';
with 'BalanceOfPower::Role::Supporter';
with 'BalanceOfPower::Role::Merchant';
with 'BalanceOfPower::Role::Warlord';
with 'BalanceOfPower::Role::CrisisManager';
with 'BalanceOfPower::Role::Historian';
with 'BalanceOfPower::Role::Analyst';

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
sub correct_nation_name
{
    my $self = shift;
    my $nation = shift;
    return undef if(! $nation);
    for(@{$self->nation_names})
    {
        return $_ if(uc $_ eq uc $nation);
    }
    return undef;
}
sub get_player_nation
{
    my $self = shift;
    return $self->get_nation($self->player_nation);
}
sub check_nation_name
{
    my $self = shift;
    my $name = shift;
    return grep {$_ eq $name} @{$self->nation_names};
}

sub load_nations_data
{
    my $self = shift;
    my $datafile = shift;
    my $file = $self->data_directory . "/" . $datafile;
    open(my $nations_file, "<", $file) || die $!;
    my $area;
    my %nations_data;
    for(<$nations_file>)
    {
        my $n = $_;
        chomp $n;
        if(! ($n =~ /^#/))
        {
            my ($name, $size, $government) = split(',', $n);
            if($government eq 'd')
            {
                $government = 'democracy';
            }
            elsif($government eq 'D')
            {
                $government = 'dictatorship';
            }
            $nations_data{$name} = { area => $area,
                                     size => $size,
                                     government => $government }

        }
        else
        {
            $n =~ /^# (.*)$/;
            $area = $1;
        }
    }
    return %nations_data;
}

#Initial values, randomly generated
sub init_random
{
    my $self = shift;
    my $datafile = shift;
    my $bordersfile = shift;
    my %nations_data = $self->load_nations_data($datafile);
    my $flags = shift;

    my $trades = 1;
    my $diplomacy = 1;
    my $alliances = 1;
    if($flags)
    {
        $trades = $flags->{'trades'}
            if(exists $flags->{'trades'});
        $diplomacy = $flags->{'diplomacy'}
            if(exists $flags->{'diplomacy'});
        $alliances = $flags->{'alliances'}
            if(exists $flags->{'alliances'});

    }

    $self->delete_log();
    $self->dice->delete_log();
    my @nation_names = ();
    foreach my $n (keys %nations_data)
    {
        push @nation_names, $n;
        say "Working on $n";
        my $export_quote = $self->random10(MIN_EXPORT_QUOTE, MAX_EXPORT_QUOTE, "Export quote $n");
        say "  export quote: $export_quote";
        my $government_strength = $self->random10(MIN_GOVERNMENT_STRENGTH, MAX_GOVERNMENT_STRENGTH, "Government strenght $n");
        say "  government strength: $government_strength";
        push @{$self->nations}, BalanceOfPower::Nation->new( 
            name => $n, 
            area => $nations_data{$n}->{area}, 
            size => $nations_data{$n}->{size},
            government => $nations_data{$n}->{government},
            export_quote => $export_quote, 
            government_strength => $government_strength);
    }
    $self->nation_names(\@nation_names);
    $self->load_borders($bordersfile);
    if($trades)
    {
        say "Trades generation...";
        $self->init_trades();
    }
    else
    {
        say "Trades generation skipped";
    }
    if($diplomacy)
    {
        say "Diplomacy generation...";
        $self->init_diplomacy();
    }
    else
    {
        say "Diplomacy generation skipped";
    }
    if($alliances)
    {
        say "Alliances generation...";
        $self->init_random_alliances();
    }
    else
    {
        say "Alliances generation skipped";
    }
}

#Group function for all the steps involved in a turn
sub elaborate_turn
{
    my $self = shift;
    my $t = shift;
    $self->init_year($t);
    $self->war_debts();
    $self->crisis_generator();
    $self->execute_decisions();
    $self->economy();
    $self->warfare();
    $self->internal_conflict();
    $self->register_global_data();
    $self->collect_events();
}

#To automatically generate turns
sub autopilot
{
    my $self = shift;
    my $start = shift;
    my $stop = shift;
    $self->autoplay(1);
    for($start..$stop)
    {
        my $y = $_;
        foreach my $t (get_year_turns($y))
        {
            $self->elaborate_turn($t);
        }
    }
    $self->autoplay(0);
}


# Configure current year
# Give production to countries. Countries split it between export and domestic and, if allowed, raise the debt in case of necessity
# Wealth reset
# Production and debt recorded
sub init_year
{
    my $self = shift;
    my $turn = shift;
    if(! $turn)
    {
        $turn = next_turn($self->current_year);
    }
    $self->log("--- $turn ---");
    say $turn;
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

    my @newgov = $nation->get_events("NEW GOVERNMENT CREATED", prev_turn($nation->current_year));
    my $previous_production = $self->get_statistics_value(prev_turn($nation->current_year), $nation->name, 'production'); 
    
    return () if(@newgov > 0);
    return () if(! $previous_production);
    
    my @prods = ();
    for(my $i = 0; $i < PRODUCTION_UNITS->[$nation->size]; $i++)
    {
        push @prods, $self->get_statistics_value(prev_turn($nation->current_year), $nation->name, 'production' . $i); 
    }
    return @prods;
}
sub calculate_production
{
    my $self = shift;
    my $n = shift;
    my @prev_prods = $self->get_base_production($n);
    my @next_prods = ();
    my $cost_for_retreat = 0;
    my @retreats = $n->get_events("RETREAT FROM", prev_turn($n->current_year));
    my $global_production = 0;
    for(my $i = 0; $i < PRODUCTION_UNITS->[$n->size]; $i++)
    {
        if(@prev_prods > 0)
        {
            $next_prods[$i] = $prev_prods[$i] + $self->random10(MIN_DELTA_PRODUCTION, MAX_DELTA_PRODUCTION, "Delta production" . $i . " " . $n->name);
        }
        else
        {
            $next_prods[$i] = $self->random10(MIN_STARTING_PRODUCTION, MAX_STARTING_PRODUCTION, "Starting production" . $i . " " . $n->name);
        }

        #DEFEAT COST MANAGEMENT
        if(@retreats)
        {
            $next_prods[$i] -= ATTACK_FAILED_PRODUCTION_MALUS;
            $cost_for_retreat += ATTACK_FAILED_PRODUCTION_MALUS;
        }
        $next_prods[$i] = 0 if($next_prods[$i] < 0);
        $next_prods[$i] = MAX_PRODUCTION if($next_prods[$i] > MAX_PRODUCTION);

        $self->set_statistics_value($n, 'production' . $i, $next_prods[$i]);
        $global_production += $next_prods[$i];
    }
    if($cost_for_retreat)
    {
        $self->send_event("COST FOR DEFEAT ON PRODUCTION: " . $cost_for_retreat);
    }
    return $global_production;
}


#Conquered nations give to the conqueror a quote of their production at start of the turn
sub war_debts
{
    my $self = shift;
    for($self->influences->all())
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
        elsif($d =~ /^(.*): BOOST PRODUCTION$/)
        {
           my $nation = $self->get_nation($1);
           $nation->boost_production();
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
        elsif($d =~ /^(.*): MILITARY SUPPORT (.*)$/)
        {
            my $supporter = $self->get_nation($1);
            my $supported = $self->get_nation($2);
            if($supported->accept_military_support($supporter, $self))
            {
                $self->start_military_support($supporter, $supported);
            }
            else
            {
                $self->broadcast_event($supported->name . " REFUSED MILITARY SUPPORT FROM " . $supporter->name);
            }
        }
        elsif($d =~ /^(.*): RECALL MILITARY SUPPORT (.*)$/)
        {
           my $supporter = $self->get_nation($1);
           my $supported = $self->get_nation($2);
           $self->stop_military_support($supporter, $supported);
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
       @route_adders = $self->shuffle("Route adders", @route_adders); 
       my $done = 0;
       while(! $done)
       {
            my $node1 = shift @route_adders;
            if($self->suitable_route_creator($node1))
            {
                if(@route_adders == 0)
                {
                    $self->send_event("TRADEROUTE CREATION FAILED FOR LACK OF PARTNERS", $node1);
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
                        $self->send_event("TRADEROUTE CREATION FAILED FOR LACK OF PARTNERS", $node1);
                    }
                }
            }
            else
            {
                $self->broadcast_event("TRADEROUTE CREATION NOT POSSIBLE FOR $node1", $node1);
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
        my $decision;
        if($nation->name eq $self->player_nation && ! $self->autoplay)
        {
            if($self->order)
            {
                $decision = $nation->name . ": " . $self->order;
                $self->order(undef);
            }
        }
        else
        {
            $decision = $nation->decision($self);
        }
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

sub internal_conflict
{
    my $self = shift;
    foreach my $n (@{$self->nations})
    {
        my $present_status = $n->internal_disorder_status;

        $n->calculate_disorder($self);
        
        #This should happen only if status changed during this iteration
        if($n->internal_disorder_status eq 'Civil war' && $present_status ne 'Civil war')
        {
            $self->lose_war($n->name, 1);
        }
        
        #my $winner = $n->fight_civil_war($self->random(0, 100, "Civil war " . $n->name . ": government fight result"), $self->random(0, 100, "Civil war " . $n->name . ": rebels fight result"));
        my $winner = $n->fight_civil_war($self);
        if($winner && $winner eq 'rebels')
        {
            $n->new_government($self);
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
    my $crises = $self->get_all_crises();
    my $wars = $self->wars->all();
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
                             "NEW GOVERNMENT CREATED",
                             "TRADEROUTE CREATION FAILED FOR LACK OF PARTNERS");
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

### Commands

sub build_commands
{
    my $self = shift;
    my $commands = BalanceOfPower::Commands->new( world => $self, log_name => 'bop-commands.log', log_active => $self->log_active );
    $commands->init();
    return $commands;
}



1;
