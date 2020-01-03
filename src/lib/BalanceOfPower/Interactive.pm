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
    my %values = ();
    my %explanations = ();
    my %already = ();
    foreach my $e (@events)
    {
        my $event_tag = $e->{code} . '-' . join('-', @{$e->{involved}});
        if(! exists $already{$event_tag})
        {
            $already{$event_tag} = 1;
            my $i = 0;
            for(@{$self->event_values->{$e->{code}}})
            {
                my $v = $_;
                if(exists $explanations{$e->{involved}->[$i]})
                {
                    push @{$explanations{$e->{involved}->[$i]}}, $e->{code} . ": " . $v;
                }
                else
                {
                    $explanations{$e->{involved}->[$i]} = [ $e->{code} . ": " . $v ];
                }
                if(exists $values{$e->{involved}->[$i]} )
                {
                    $values{$e->{involved}->[$i]} += $v
                }   
                else
                {
                    $values{$e->{involved}->[$i]} = $v
                }
                $i++;
            }
        }
    }
    return \%values, \%explanations;
}

sub elaborate_average
{
    my $self = shift;
    my $turn = shift;
    my ($values, undef) = $self->elaborate_values($turn);
    my $count = 0;
    my $sum = 0;
    for(keys %{$values})
    {
        $count++;
        $sum += $values->{$_};
    }
    return $sum, $count, $sum/$count;
}

sub calculate_bet_return
{
    my $self = shift;
    my $turn = shift;
    my $bet = shift;
    my ($values, undef) = $self->elaborate_values($turn);
    my ($sum, $count, $average) = $self->elaborate_average($turn);
    my $nation = $bet->{nation};
    my $delta = $values->{$nation} - $average;
    $delta = $delta * (-1) if $bet->{side} eq 'against';
    my $new_value = $bet->{value} + ( $delta * $bet->{value} );
    return sprintf("%.2f", $new_value);
    
}


1;
