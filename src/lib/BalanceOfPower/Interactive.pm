package BalanceOfPower::Interactive;

use strict;
use v5.10;

use Moo;
use JSON::Parse 'json_file_to_perl';
use Cwd 'abs_path';
use File::Path 'make_path';
use MongoDB;

has game => (
    is => 'ro',
);

has event_values => (
    is => 'lazy'
);
sub _build_event_values {
    my $module_file_path = __FILE__;
    my $root_path = abs_path($module_file_path);
    $root_path =~ s/Interactive\.pm//;
    my $data_directory = $root_path . "data";
    return json_file_to_perl("$data_directory/events_interactive_values.json");
}

sub elaborate_values
{
    my $self = shift;
    my $turn = shift;
    my $mongo = MongoDB->connect(); 
    my $db = $mongo->get_database('bop_' . $self->game . '_runtime');
    my @events = $db->get_collection('events')->find({ time => $turn})->all();
    my %nations = ();
    foreach my $e (@events)
    {
        my $i = 0;
        for(@{$self->event_values->{$e->{code}}})
        {
            my $v = $_;
            if(exists $nations{$e->{involved}->[$i]} )
            {
                $nations{$e->{involved}->[$i]} += $v
            }   
            else
            {
                $nations{$e->{involved}->[$i]} = $v
            }
        }
    }
    return \%nations;
}

1;
