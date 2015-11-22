package BalanceOfPower::Nation::Role::IA;

use strict;
use v5.10;
use Moo::Role;
use Array::Utils qw(intersect);

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw( prev_turn );

has executive => (
    is => 'ro',
    handles => { decide => 'decide' }
    
);

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
            $decision = $self->domestic_advisor();
        }
        elsif($a eq 'economy')
        {
            $decision = $self->economy_advisor();
        }
        elsif($a eq 'military')
        {
            $decision = $self->military_advisor();
        }
        return $self->name .  ": " . $decision if($decision);
    }
    return undef;
}

sub advisor
{
    my $self = shift;
    my @orders = @_;
    my $order = undef;
    for(@orders)
    {
        $order = $self->decide($_);
        return $order if $order;
    }
    return undef;
}

sub domestic_advisor
{
    my $self = shift;
    return $self->advisor("LOWER ORDER", 
                          "BOOST PRODUCTION",
                          "TREATY NAG WITH");
}

sub economy_advisor
{
    my $self = shift;
    return $self->advisor("TREATY COM WITH", 
                          "DELETE TRADEROUTE",
                          "ADD ROUTE",
                          "ECONOMIC AID");
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
    return $self->advisor("DECLARE WAR", 
                          "AID INSURGENTS",
                          "MILITARY SUPPORT",
                          "REBEL MILITARY SUPPORT",
                          "RECALL MILITARY SUPPORT",
                          "BUILD TROOPS");
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

