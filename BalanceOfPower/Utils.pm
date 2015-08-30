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

sub prev_turn
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
sub next_turn
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
sub from_to_turns
{
    my $from = shift;
    my $to = shift;
    my $from_y;
    my $from_t;
    my $to_y;
    my $to_t;
    if($from =~ /(\d+)(\/(\d+))?/)
    {
        $from_y = $1;
        $from_t = $3 ? $3 : 1;
    }
    else
    {
        return ();
    }
    if($to =~ /(\d+)(\/(\d+))?/)
    {
        $to_y = $1;
        $to_t = $3 ? $3 : 1;
    }
    else
    {
        return ();
    }
    return ()
        if($to_y < $from_y || ($to_y == $from_y && $to_t < $from_t)); 
    my $goon = 1;
    my $to_add_y = $from_y;
    my $to_add_t = $from_t;
    my @turns = ();
    while(1)
    {
        my $to_add = $to_add_y . '/' . $to_add_t;
        push @turns, $to_add;
        last if($to_add eq $to);
        if($to_add_t < TURNS_FOR_YEAR)
        {
            $to_add_t++;
        }
        else
        {
            $to_add_y++;
            $to_add_t = 1;
        }
    }
    return @turns;
}

sub as_title
{
    my $text = shift;
    return color("yellow bold") . $text . color("reset");
}

our @EXPORT_OK = ('prev_turn', 'next_turn', 'random', 'random10', 'get_year_turns', 'as_title', 'from_to_turns');

1;
