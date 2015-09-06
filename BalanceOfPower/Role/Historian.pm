package BalanceOfPower::Role::Historian;

use strict;
use Moo::Role;
use Term::ANSIColor;
use Data::Dumper;

use BalanceOfPower::Utils qw( get_year_turns as_title from_to_turns );
use BalanceOfPower::Constants ':all';

with 'BalanceOfPower::Role::Reporter';

has statistics => (
    is => 'rw',
    default => sub { {} }
);

requires 'get_nation';
requires 'routes_for_node';
requires 'get_allies';
requires 'get_crises';
requires 'get_wars';
requires 'print_nation_situation';



sub get_statistics_value
{
    my $self = shift;
    my $turn = shift;
    my $nation = shift;
    my $value = shift;
    if(exists $self->statistics->{$turn})
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
sub print_nation_actual_situation
{
    my $self = shift;
    my $nation = shift;
    my $turn = $self->current_year;
    my $nation_obj = $self->get_nation($nation);
    my $out = as_title("$nation\n===\n");
    $out .= $nation_obj->print_attributes();
    $out .= "\n";
    $out .= $self->print_nation_situation($nation);
    $out .= "\n";
    $out .= "\n";
    $out .= $self->print_nation_statistics_header() . "\n";
    $out .= $self->print_nation_statistics_line($nation, $turn) . "\n\n";
    $out .= as_title("TRADEROUTES\n---\n");
    foreach my $tr ($self->routes_for_node($nation))
    {
        $out .= $tr->print($nation) . "\n";
    }
    $out .= "\n";
    $out .= as_title("ALLIES\n---\n");
    $out .= $self->print_allies($nation);
    $out .="\n";
    my $crises_wars_title = sprintf "%-35s %-35s", "CRISES", "WARS";
    $crises_wars_title .="\n";
    $crises_wars_title .= sprintf "%-35s %-35s", "---", "---";
    $crises_wars_title .="\n";
    $out .= as_title($crises_wars_title);
    my @crises = $self->get_crises($nation);
    my @wars = $self->get_wars($nation);
    for(my $i = 0; ;$i++)
    {
        last if(@crises == 0 && @wars == 0);
        my $crisis_text = "";
        if(@crises)
        {
            my $c = shift @crises;
            $crisis_text = $c->print;
        }
        my $war_text = "";
        if(@wars)
        {
            my $w = shift @wars;
            $war_text = $w->print;
        }
        $out .= sprintf "%-35s %-35s", $crisis_text, $war_text;
        $out .="\n";
    }
    return $out;
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
sub print_nation_statistics_header
{
    if(DEBT_ALLOWED)
    {
        return "Prod.\tWealth\tGrowth\tDelta\tDebt\tDisor.\tArmy";
    }
    else
    {
        return "Prod.\tWealth\tGrowth\tDelta\tDisor.\tArmy";
    }
}
sub print_nation_statistics_line
{
    my $self = shift;
    my $nation = shift;
    my $y = shift;
    my $out = "";
    #$out .= "$y\t";
    $out .= $self->get_statistics_value($y, $nation, 'production') . "\t";
    $out .= $self->get_statistics_value($y, $nation, 'wealth') . "\t";
    if($self->get_statistics_value($y, $nation, 'production') <= 0)
    {
        $out .= "X\t";
    }
    else
    {
        $out .= int(($self->get_statistics_value($y, $nation, 'wealth') / $self->get_statistics_value($y, $nation, 'production')) * 100) / 100 . "\t";
    }
    $out .= $self->get_statistics_value($y, $nation, 'wealth') - $self->get_statistics_value($y, $nation, 'production') . "\t";
    if(DEBT_ALLOWED)
    {
        $out .= $self->get_statistics_value($y, $nation, 'debt') . "\t";
    }
    $out .= $self->get_statistics_value($y, $nation, 'internal disorder') . "\t";
    $out .= $self->get_statistics_value($y, $nation, 'army') . "\t";
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
    my @nations = @{$self->nation_names};

    my $out = "";
    $out .= as_title(sprintf "%-16s %-16s", "Nation" , $self->print_nation_statistics_header() . "\n");
    for(@nations)
    {
        $out .= sprintf "%-16s %-16s", $_ , $self->print_nation_statistics_line($_, $y) . "\n";
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




