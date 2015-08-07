package BalanceOfPower::Role::Historian;

use strict;
use Moo::Role;
use Data::Dumper;

use BalanceOfPower::Utils qw(prev_year next_year random random10 get_year_turns);

has statistics => (
    is => 'rw',
    default => sub { {} }
);
has events => (
    is => 'rw',
    default => sub { {} }
);

requires 'get_nation';



sub register_event
{
    my $self = shift;
    my $event = shift;
    my $n1 = shift || "";
    my $n2 = shift || "";
    if(! exists $self->events->{$self->current_year})
    {
        $self->events->{$self->current_year} = ();
    }
    push @{$self->events->{$self->current_year}}, $event;
    if($n1 ne "")
    {
        my $nation = $self->get_nation($n1);
        $nation->register_event($event);
    }
    if($n2 ne "")
    {
        my $nation = $self->get_nation($n2);
        $nation->register_event($event);
    }
}
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
sub print_nation_statistics
{
    my $self = shift;
    my $nation = shift;
    my $first_year = shift;
    my $last_year = shift;
    my $out;
    $out .= $self->print_nation_statistics_header() . "\n";
    foreach my $y ($first_year..$last_year)
    {
        foreach my $t (get_year_turns($y))
        {
            $out .= $self->print_nation_statistics_line($nation, $t) . "\n";
        }
    }
    return $out;
}
sub print_nation_statistics_header
{
    return "Year\tProd.\tWealth\tGrowth\tDelta\tDebt\tDisor.\tArmy";
}
sub print_nation_statistics_line
{
    my $self = shift;
    my $nation = shift;
    my $y = shift;
    my $out = "";
    $out .= "$y\t";
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
    $out .= $self->get_statistics_value($y, $nation, 'debt') . "\t";
    $out .= $self->get_statistics_value($y, $nation, 'internal disorder') . "\t";
    $out .= $self->get_statistics_value($y, $nation, 'army') . "\t";
    return $out;
}
sub print_year_statistics
{
    my $self = shift;
    my $y = shift;
    my @nations = @_;
    my $out = "Medium values:\n";
    $out .= "Year\tProd.\tWealth\tInt.Dis\n";
    foreach my $t (get_year_turns($y))
    {
        my ($prod, $wealth, $disorder) = $self->medium_statistics($t, @nations);
        $out .= "$t\t$prod\t$wealth\t$disorder\n";
    }
    $out .= "\n";
    foreach my $n (@nations)
    {
        $out .=  $n . ":\n";
        $out .= $self->print_nation_statistics_header() . "\n";
        foreach my $t (get_year_turns($y))
        {
            $out .= $self->print_nation_statistics_line($n, $t) . "\n";
        }
        $out .= "\n";
    }
    $out .= "\nEvents of the year:\n";
    foreach my $t (get_year_turns($y))
    {
        $out .= " - $t\n";
        foreach my $e (@{$self->events->{$t}})
        {
            $out .= " " . $e . "\n";
        }
    }
    return $out; 
}
sub print_overall_statistics
{
    my $self =shift;
    my $first_year = shift;
    my $last_year = shift;
    my @nations = @_;
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
    my @nations = @_;
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




