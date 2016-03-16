package BalanceOfPower::Role::Reporter;

use strict;
use utf8;
use v5.10;
use Moo::Role;
use BalanceOfPower::Utils qw( prev_turn get_year_turns as_title );
use BalanceOfPower::Printer;

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
    my $title = shift;
    my $backlog = shift || 0;
    my $mode = shift || 'print';
    my @to_print;
    if(! $y)
    {
        $y = $self->current_year ? $self->current_year : "START";
    }
    if($y =~ /^\d\d\d\d$/)
    {
        @to_print = get_year_turns($y);
    }
    elsif($y =~ /^\d\d\d\d\/\d+$/)
    {
        @to_print = ($y);
        for(my $i = 0; $i < $backlog; $i++)
        {
            push @to_print, prev_turn($y);
            $y = prev_turn($y);
        }
    }
    elsif($y eq 'START')
    {
        @to_print = ('START');
    }
    else
    {
        return "";
    }
    return BalanceOfPower::Printer::print($mode, $self, 'print_turn_events', 
                                   { title => $title,
                                     turns => \@to_print,
                                     events => $self->events } );
}
sub get_turn_tags
{
    my $self = shift;
    sub sort_start
    {
        return 0 if($a eq $b);
        return -1 if($a eq 'START');
        return 1 if($b eq 'START');
        return 1 if($a gt $b);
        return -1 if($b gt $a);
    }
    return sort sort_start keys %{$self->events};
}


sub dump_events
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
  
    foreach my $y ($self->get_turn_tags())
    {
        print {$io} $indent . "### $y\n";
        foreach my $e (@{$self->events->{$y}})
        {
            print {$io} $indent . $e . "\n";
        }
    }
}
sub load_events
{
    my $self = shift;
    my $data = shift;
    my @lines = split "\n", $data;
    my $year = "";
    my %events;
    foreach my $l (@lines)
    {
        $l =~ s/^\s//;
        chomp $l;
        if($l =~ /### (.*)$/)
        {
            $year = $1;
            $events{$year} = [];
        }
        else
        {
            push @{$events{$year}}, $l;
        }
    }
    return \%events;
}


1;
