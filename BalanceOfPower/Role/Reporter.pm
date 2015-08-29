package BalanceOfPower::Role::Reporter;

use strict;
use v5.10;
use Moo::Role;
use BalanceOfPower::Utils qw( get_year_turns as_title );


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

    open(my $log, ">>", "bop.log");
    print $log "[" . $self->name . "] $event\n";
    close($log);
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
    else
    {
        return "";
    }
    foreach my $t (@to_print)
    {
        $out .= as_title(" - $t\n");
        foreach my $e (@{$self->events->{$t}})
        {
            $out .= " " . $e . "\n";
        }
    }
    return $out; 
}


1;
