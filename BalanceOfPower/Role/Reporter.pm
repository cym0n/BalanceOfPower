package BalanceOfPower::Role::Reporter;

use strict;
use v5.10;
use Moo::Role;


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


1;
