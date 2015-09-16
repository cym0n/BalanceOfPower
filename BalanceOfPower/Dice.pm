package BalanceOfPower::Dice;

use v5.10;
use Moo;
use Data::Dumper;
use List::Util qw(shuffle);

has tricks => (
    is => 'rw',
    default => sub { {} } 
);
has trick_counters => (
    is => 'rw',
    default => sub { {} }
);
has forced_advisor => (
    is => 'rw',
    default => 0
);
has only_one_nation_acting => (
    is => 'rw',
    default => 0
);

sub random
{
    my $self = shift;
    my $min = shift;
    my $max = shift;
    my $message = shift || "NO MESSAGE [$min-$max]";
    my $out = $self->tricked($message);
    if(defined $out)
    {
        $self->log($message, $out, 1);
        return $out;
    }
    else
    {
        my $random_range = $max - $min + 1;
        $out = int(rand($random_range)) + $min;
        $self->log($message, $out, 0);
        return $out;
    }
}

sub random10
{
    my $self = shift;
    my $min = shift;
    my $max = shift;
    my $message = shift || "NO MESSAGE [$min-$max]";
    my $out = $self->tricked($message);
    if(defined $out)
    {
        $self->log($message, $out, 1);
        return $out;
    }
    else
    {
        my $random_range = (($max - $min) / 10) + 1;
        $out = (int(rand($random_range)) * 10) + $min;
        $self->log($message, $out, 0);
        return $out;
    }
}
sub shuffle_array
{
    my $self = shift;
    my $message = shift || "NO MESSAGE IN SHUFFLE";
    my @array = @_;
    if($message =~ /^Choosing advisor for (.*)$/) 
    {
        my $nation = $1;
        my @array_back;
        my $tricked = 0;
        if($self->forced_advisor())
        {
            @array_back = ( $self->forced_advisor() );
            $tricked = 1;
        }
        else
        {
            @array_back = shuffle @array;
        }
        if($self->only_one_nation_acting)
        {
            if($self->only_one_nation_acting ne $nation)
            {
                @array_back = ("Noone");
                $tricked = 1;
            }
        }
        $self->log($message, "<<array>>, first result: " . $array_back[0], $tricked);
        return @array_back
    }

    if(@array == 0)
    {
        $self->log($message, "<<array>>, Array empty");
        return @array;
    }
    @array = shuffle @array;
    $self->log($message, "<<array>>, first result: " . $array[0]);
    return @array;
}
sub tricked
{
    my $self = shift;
    my $message = shift;
    if(exists $self->tricks->{$message})
    {
        my $index;
        if(exists $self->trick_counters->{$message})
        {
            $index = $self->trick_counters->{$message};
        }
        else
        {
            $index = 0;
        }
        my $result;
        if(exists $self->tricks->{$message}->[$index])
        {
            $result = $self->tricks->{$message}->[$index];
        }
        else
        {
            $result = undef;
        }
        $self->trick_counters->{$message} = $index + 1;
        return $result;
    }
    else
    {
        return undef;
    } 
}

sub log
{
    my $self = shift;
    my $message = shift;
    my $result = shift;
    my $tricked = shift;
    if($tricked)
    {
        $message .= " *TRICKED* ";
    }
    open(my $log, ">>", "bop-dice.log");
    print $log "[" . $message . "] $result\n";
    close($log); 
}

1;
