package BalanceOfPower::Role::Historian;

use v5.10;
use strict;
use Moo::Role;
use Term::ANSIColor;
use List::Util qw( min max );
use BalanceOfPower::Printer;
use Data::Dumper;

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
    my $mode = shift || 'print';
    my $attributes_names = ["Size", "Prod.", "Wealth", "W/D", "Growth", "Disor.", "Army", "Prog.", "Pstg."];
    my $attributes = ["production", "wealth", "w/d", "growth", "internal disorder", "army", "progress", "prestige"];
    my %data = ();

    foreach my $t (from_to_turns($first_turn, $last_turn))
    {
        my @ndata = $self->get_nation_statistics_line($nation, $t, $attributes);
        $data{$t} = \@ndata;
    }
    return BalanceOfPower::Printer::print($mode, $self, 'print_nation_statistics', 
                                   { nation => $nation,
                                     attributes => $attributes_names,
                                     statistics => \%data,
                                   } );
}
sub print_nation_factor
{
    my $self = shift;
    my $nation = shift;
    my $factor = shift;
    my $first_turn = shift;
    my $last_turn = shift;
    my $out = as_title($nation . " - " . $factor . " - column of values" . "\n===\n");
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

sub plot_nation_factor
{
    my $self = shift;
    my $nation = shift;
    my $factor = shift;
    my $first_turn = shift;
    my $last_turn = shift;
    
    my $graph_height = 12;

    my @data = ();
    my $valid = 0;
    foreach my $t (from_to_turns($first_turn, $last_turn))
    {
        if(defined $self->get_statistics_value($t, $nation, $factor))
        {
            push @data, $self->get_statistics_value($t, $nation, $factor);
            $valid = 1;
        }
        else
        {
            push @data, undef;
        }
    }
    return "" if(! $valid);
    my $min = min @data;
    my $max = max @data;
    my $step = ($max - $min) / $graph_height;
    my @lines = ();
    my $out = as_title($nation . " - " . $factor . " - graph " . "\n===\n");
    $out .= "Min. value: $min   Max. value: $max\n\n";
    for(my $i = 0; $i <= $graph_height; $i++)
    {
        $lines[$i] = "";
        my $level =  $step * ( $graph_height - $i);
        for(@data)
        {
            my $v = $_;
            if(! $v)
            {
                $lines[$i] .= " ";
            }
            else
            {
                #if(($v - $min) < $step * ( $graph_height - ($i-1)) && 
                if(($v - $min) >= $level)
                {
                    $lines[$i] .= "o";
                }
                else
                {
                    $lines[$i] .= " ";
                }
            }
        }
        my $level_label = int($level * 100) / 100 + $min;
        $out .= $lines[$i] . "...$level_label" ."\n";
    }
    return $out . "\n";
}


sub print_nation_statistics_header
{
    if(DEBT_ALLOWED)
    {
        return "Size\tProd.\tWealth\tW/D\tGrowth\tDebt\tDisor.\tArmy\tProg.\tPstg.";
    }
    else
    {
        return "Size\tProd.\tWealth\tW/D\tGrowth\tDisor.\tArmy\tProg.\tPstg.";
    }
}
sub get_nation_statistics_line
{
    my $self = shift;
    my $nation = shift;
    my $y = shift;
    my $characteristics = shift;
    my @out = ();
    push @out, $self->get_nation($nation)->size;
    for(@{$characteristics})
    {
        push @out, $self->get_statistics_value($y, $nation, $_);
    }
    return @out;
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
    $out .= $self->get_statistics_value($y, $nation, 'progress') . "\t";
    $out .= $self->get_statistics_value($y, $nation, 'prestige') . "\t";
    return $out;
}



sub print_formatted_turn_events
{
    my $self = shift;
    my $y = shift;
    my $title = shift;
    my $mode = shift || 'print';
    my $out = "";
    $out .= $self->print_turn_events($y, $title, 0, $mode);
    return $out;
}

sub print_nation_events
{
    my $self = shift;
    my $nation_name = shift;
    my $y = shift;
    my $title = shift;
    my $mode = shift || 'print';
    my $nation = $self->get_nation($nation_name);
    return $nation->print_turn_events($y, $title, 0, $mode);
}

sub print_turn_statistics
{
    my $self = shift;
    my $y = shift;
    my $order = shift;
    my $mode = shift || 'print';
    my @nations = @{$self->nation_names};
    my $attributes_names = ["Size", "Prod.", "Wealth", "W/D", "Disor.", "Army", "Prog.", "Pstg."];
    my $attributes = ["production", "wealth", "w/d", "internal disorder", "army", "progress", "prestige"];
    my %data = ();
    my @names;
    if($order)
    {
        my @ordered = $self->order_statistics($y, lc $order);
        for(@ordered)
        {
            push @names, $_->{nation};
        } 
    }
    else
    {
        @names = @nations;
    }
    for(@names)
    {
        my @ndata = $self->get_nation_statistics_line($_, $y, $attributes);
        $data{$_} = \@ndata;
    }
    return BalanceOfPower::Printer::print($mode, $self, 'print_turn_statistics', 
                                   { year => $y,
                                     order => $order,
                                     attributes => $attributes_names,
                                     statistics => \%data,
                                     names => \@names, });
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

sub dump_statistics
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
    my $dump = Data::Dumper->new([$self->statistics]);
    $dump->Indent(0);
    print {$io} $indent . $dump->Dump . "\n";
}
sub load_statistics
{
    my $self = shift;
    my $data = shift;
    my $VAR1;
    eval ( $data );
    $self->statistics($VAR1);
}


1;




