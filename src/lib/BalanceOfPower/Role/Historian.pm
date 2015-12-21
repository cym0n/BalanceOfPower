package BalanceOfPower::Role::Historian;

use v5.10;
use strict;
use Moo::Role;
use Term::ANSIColor;

use BalanceOfPower::Utils qw( get_year_turns as_title from_to_turns );
use BalanceOfPower::Constants ':all';

with 'BalanceOfPower::Role::Reporter';

has statistics => (
    is => 'rw',
    default => sub { {} }
);

requires 'get_nation';



sub get_statistics_value
{
    my $self = shift;
    my $turn = shift;
    my $nation = shift;
    my $value = shift;
    if($turn && exists $self->statistics->{$turn})
    {
        if($nation)
        {
            return $self->statistics->{$turn}->{$nation}->{$value};
        }
        else
        {
            return $self->statistics->{$turn}->{$value};
        }
    }
    else
    {
        return undef;
    }
}
sub set_statistics_value
{
    my $self = shift;
    my $nation = shift;
    my $value_name = shift;
    my $value = shift;
    if($nation)
    {
        $self->statistics->{$nation->current_year}->{$nation->name}->{$value_name} = $value;
    }
    else
    {
        $self->statistics->{$self->current_year}->{$value_name} = $value;
    }
}

sub print_nation_statistics
{
    my $self = shift;
    my $nation = shift;
    my $first_turn = shift;
    my $last_turn = shift;
    my $out = as_title($nation . "\n===\n");
    
    $out .= "Year\t" . $self->print_nation_statistics_header() . "\n";
    foreach my $t (from_to_turns($first_turn, $last_turn))
    {
        $out .= $t . "\t" . $self->print_nation_statistics_line($nation, $t) . "\n";
    }
    return $out;
}
sub print_nation_factor
{
    my $self = shift;
    my $nation = shift;
    my $factor = shift;
    my $first_turn = shift;
    my $last_turn = shift;
    my $out = as_title($nation . "\n===\n");
    foreach my $t (from_to_turns($first_turn, $last_turn))
    {
        if(defined $self->get_statistics_value($t, $nation, $factor))
        {
            $out .=  $self->get_statistics_value($t, $nation, $factor) . "\n";
        }
        else
        {
            $out .= "*** UNAVAILABLE ***" . "\n";
        }
    }
    return $out;
}


sub print_nation_statistics_header
{
    if(DEBT_ALLOWED)
    {
        return "Size\tProd.\tWealth\tW/D\tGrowth\tDebt\tDisor.\tArmy\tPstg.";
    }
    else
    {
        return "Size\tProd.\tWealth\tW/D\tGrowth\tDisor.\tArmy\tPstg.";
    }
}
sub print_nation_statistics_line
{
    my $self = shift;
    my $nation = shift;
    my $y = shift;
    my $out = "";
    $out .= $self->get_nation($nation)->size . "\t";
    if(! defined $self->get_statistics_value($y, $nation, 'production'))
    {
        $out .= "###            no statistics available           ###";
        return $out;
    }
    $out .= $self->get_statistics_value($y, $nation, 'production') . "\t";
    $out .= $self->get_statistics_value($y, $nation, 'wealth') . "\t";
    $out .= $self->get_statistics_value($y, $nation, 'w/d') . "\t";
    $out .= $self->get_statistics_value($y, $nation, 'growth') . "\t";
    if(DEBT_ALLOWED)
    {
        $out .= $self->get_statistics_value($y, $nation, 'debt') . "\t";
    }
    $out .= $self->get_statistics_value($y, $nation, 'internal disorder') . "\t";
    $out .= $self->get_statistics_value($y, $nation, 'army') . "\t";
    $out .= $self->get_statistics_value($y, $nation, 'prestige') . "\t";
    return $out;
}



sub print_formatted_turn_events
{
    my $self = shift;
    my $y = shift;
    my $out = "";
    $out .= as_title("\nEvents:\n");
    $out .= $self->print_turn_events($y);
    return $out;
}

sub print_nation_events
{
    my $self = shift;
    my $nation_name = shift;
    my $y = shift;
    my $nation = $self->get_nation($nation_name);
    my $turn = shift;
    return $nation->print_turn_events($y);
}

sub print_turn_statistics
{
    my $self = shift;
    my $y = shift;
    my $order = shift;
    my @nations = @{$self->nation_names};
    my $out = "";
    $out .= as_title(sprintf "%-16s %-16s", "Nation" , $self->print_nation_statistics_header() . "\n");
    if($order)
    {
        my @ordered = $self->order_statistics($y, lc $order);
        for(@ordered)
        {
            my $n = $_->{nation};
            $out .= sprintf "%-16s %-16s", $n , $self->print_nation_statistics_line($n, $y) . "\n";
        } 
    }
    else
    {
        for(@nations)
        {
            $out .= sprintf "%-16s %-16s", $_ , $self->print_nation_statistics_line($_, $y) . "\n";
        }
    }
    $out .= "\n";
    return $out;
}

sub print_overall_statistics
{
    my $self =shift;
    my $first_year = shift;
    my $last_year = shift;
    my @nations = @{$self->nation_names};
    my $out = "Overall medium values\n";
    $out .= "Year\tProd.\tWealth\tInt.Dis\n";
    foreach my $y ($first_year..$last_year)
    {
        foreach my $t (get_year_turns($y))
        {
            my ($prod, $wealth, $disorder) = $self->medium_statistics($t, @nations);
            $out .= "$y\t$prod\t$wealth\t$disorder\n";
        }
    }
    return $out;
}
sub medium_statistics
{
    my $self = shift;
    my $year = shift;
    my @nations = @{$self->nation_names};
    my $total_production = 0;
    my $total_wealth = 0;
    my $total_disorder = 0;
    foreach my $t (get_year_turns($year))
    {
        foreach my $n (@nations)
        {
            $total_production += $self->get_statistics_value($t, $n, 'production');
            $total_wealth += $self->get_statistics_value($t, $n, 'wealth');
            $total_disorder += $self->get_statistics_value($t, $n, 'internal disorder');
        }
    }
    my $medium_production = int(($total_production / @nations)*100)/100;
    my $medium_wealth = int(($total_wealth / @nations)*100)/100;
    my $medium_disorder = int(($total_disorder / @nations)*100)/100;
    return ($medium_production, $medium_wealth, $medium_disorder);
}

sub order_statistics
{
    my $self = shift;
    my $turn = shift;
    my $value = shift;
    my @nations = @{$self->nation_names};
    my @ordered;
    foreach my $n (@nations)
    {
        my $val = $self->get_statistics_value($turn, $n, $value);
        if(! defined $val)
        { 
            return ();
        }
        push @ordered, { nation => $n, value => $val }; 
    }
    @ordered = sort { $b->{value} <=> $a->{value} } @ordered;
    return @ordered;
}

sub print_crises
{
    my $self = shift;
    my $year = shift;
    my $out = "";
    foreach my $t (get_year_turns($year))
    {
        my $header = 0;
        foreach my $e (@{$self->events->{$t}})
        {
            if($e =~ /^CRISIS/)
            {
                if(! $header)
                {
                    $header = 1;
                    $out .= "$t\n";
                }
                $out .= " " . $e . "\n";
            }
        }
        if($header)
        {
            $out .= "\n";
        }
    }
    return $out;
}
sub print_defcon_statistics
{
    my $self = shift;
    my $first_year = shift;
    my $last_year = shift;
    my $out = "Year\tCrises\tWars\n";
    foreach my $y ($first_year..$last_year)
    {
        foreach my $t (get_year_turns($y))
        {
            my $crises = $self->get_statistics_value($t, undef, 'crises');
            my $wars = $self->get_statistics_value($t, undef, 'wars');
            $out .= "$t\t$crises\t$wars\n";
        }
    }
    return $out;
       
}

1;




