package BalanceOfPower::Role::Reporter;

use strict;
use v5.10;
use Moo::Role;
use BalanceOfPower::Utils qw( get_year_turns as_title );

with "BalanceOfPower::Role::Logger";

has events => (
    is => 'rw',
    default => sub { {} }
);

sub register_event
{
    my $self = shift;
    my $event = shift;
    my $time = $self->current_year ? $self->current_year : "START";

    $self->events({}) if(! $self->events );
    push @{$self->events->{$time}}, $event;
    $self->log("[" . $self->name . "] $event");
}
sub get_events
{
    my $self = shift;
    my $label = shift;
    my $year = shift;
    if($self->events && exists $self->events->{$year})
    {
        my @events = grep { $_ =~ /^$label/ } @{$self->events->{$year}};
        return @events;
    }
    else
    {
        return ();
    }
}


sub print_turn_events
{
    my $self = shift;
    my $y = shift;
    return $self->_print_turn_events($y, 1);
}

sub print_turn_events_notitle
{
    my $self = shift;
    my $y = shift;
    return $self->_print_turn_events($y, 0);
}

sub print_turn_events_inline_year
{
    my $self = shift;
    my $y = shift;
    return $self->_print_turn_events($y, 2);
}


sub _print_turn_events
{
    my $self = shift;
    my $y = shift;
    my $title = shift;
    my $out = "";
    my @to_print;
    if(! $y)
    {
        $y = $self->current_year ? $self->current_year : "START";
    }
    if($y =~ /\d\d\d\d/)
    {
        @to_print = get_year_turns($y)
    }
    elsif($y =~ /\d\d\d\d\/\d+/)
    {
        @to_print = ($y);
    }
    elsif($y eq 'START')
    {
        @to_print = ('START');
    }
    else
    {
        return "";
    }
    foreach my $t (@to_print)
    {
        $out .= as_title($self->name . " - $t\n") if $title == 1;
        foreach my $e (@{$self->events->{$t}})
        {
            $out .= " ";
            $out .= $t . ": " if($title == 2);
            $out .= $e . "\n";
        }
    }
    return $out; 
}
sub dump_events
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
    sub sort_start
    {
        return 0 if($a eq $b);
        return -1 if($a eq 'START');
        return 1 if($b eq 'START');
        return 1 if($a gt $b);
        return -1 if($b gt $a);
    }
    foreach my $y (sort sort_start keys %{$self->events})
    {
        print {$io} $indent . "### $y\n";
        foreach my $e (@{$self->events->{$y}})
        {
            print {$io} $indent . $e . "\n";
        }
    }
}


1;
