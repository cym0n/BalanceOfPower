package BalanceOfPower::Utils;
use BalanceOfPower::Constants ':all';
use Term::ANSIColor;

use strict;

use base 'Exporter';

sub random
{
    my $min = shift;
    my $max = shift;
    my $random_range = $max - $min + 1;
    my $out = int(rand($random_range)) + $min;
    return $out;
}

sub random10
{
    my $min = shift;
    my $max = shift;
    my $random_range = (($max - $min) / 10) + 1;
    my $out = (int(rand($random_range)) * 10) + $min;
    return $out;
}

sub prev_year
{
    my $year = shift;
    my ($y, $i) = split '/', $year;
    if($i == 1)
    {
        return ($y -1) . '/' . TURNS_FOR_YEAR;
    }
    else
    {
        return $y . '/' . ($i - 1);
    }
}
sub next_year
{
    my $year = shift;
    my ($y, $i) = split '/', $year;
    if($i == TURNS_FOR_YEAR)
    {
        return ($y +1) . '/' . '1';
    }
    else
    {
        return $y . '/' . ($i + 1);
    }
}
sub get_year_turns
{
    my $year = shift;
    return ($year) if($year =~ /\d+\/\d+/);
    my @turns = ();
    for(my $i = 1; $i<= TURNS_FOR_YEAR; $i++)
    {
        push @turns, $year . '/' . $i;
    }
    return @turns;
}

sub as_title
{
    my $text = shift;
    return color("yellow bold") . $text . color("reset");
}

our @EXPORT_OK = ('prev_year', 'next_year', 'random', 'random10', 'get_year_turns', 'as_title');

1;
