package BalanceOfPower::Interactive;

use strict;
use v5.10;

use Moo;
use JSON::Parse 'json_file_to_perl';
use Cwd 'abs_path';
use File::Path 'make_path';
use MongoDB;
use BalanceOfPower::Utils qw(load_nations_data);

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
has nations_data => (
    is => 'lazy'
);
sub _build_nations_data {
    my $module_file_path = __FILE__;
    my $root_path = abs_path($module_file_path);
    $root_path =~ s/Interactive\.pm//;
    my $data_directory = $root_path . "data";
    my %nations_data = load_nations_data("$data_directory/nations-v2.txt");
    return \%nations_data;
}
has verbose => (
    is => 'rw',
    default => 0
);

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
                my $nat_code = $self->nations_data->{$e->{involved}->[$i]}->{code};
                my $v = $_;
                if(exists $explanations{$nat_code})
                {
                    push @{$explanations{$nat_code}}, $e->{code} . ": " . $v;
                }
                else
                {
                    $explanations{$nat_code} = [ $e->{code} . ": " . $v ];
                }
                if(exists $values{$nat_code} )
                {
                    $values{$nat_code} += $v
                }   
                else
                {
                    $values{$nat_code} = $v
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
    my $max = 0;
    my $min = 1000000;
    for(keys %{$values})
    {
        $count++;
        $sum += $values->{$_};
        $max = $values->{$_} if $values->{$_} > $max;
        $min = $values->{$_} if $values->{$_} < $min;
    }
    return $sum, $count, $sum/$count, $max, $min;
}

sub calculate_bet_return
{
    my $self = shift;
    my $turn = shift;
    my $bet = shift;
    my ($values, undef) = $self->elaborate_values($turn);
    my ($sum, $count, $average, $max, $min) = $self->elaborate_average($turn);
    my $nation = $bet->{nation};
    my $add;
    if($self->verbose)
    {
        say "SUM: $sum";
        say "COUNT: $count";
        say "AVERAGE: $average";
        say "MAX: $max";
        say "MIN: $min";
        say "Nation is $nation, side is " . $bet->{side} . ", actual value is " . $bet->{value};
        say "Value is " . $values->{$nation};
    }
    if($values->{$nation} >= $average)
    {
        my $perc = (($values->{$nation} - int($average)) * 100 ) / ($max - int($average));
        $add = $bet->{value} * ($perc / 100);
        $add = $add * (-1) if $bet->{side} eq 'against';
    }
    else
    {
        my $perc = ((int($average) - $values->{$nation}) * 100 ) / (int($average) - $min);
        $add = $bet->{value} * ($perc / 100);
        $add = $add * (-1) if $bet->{side} eq 'for';
    }
    my $new_value = $bet->{value} + $add; 
    say "New value ($add): $new_value" if($self->verbose);
    return sprintf("%.2f", $new_value);
    
}


1;
