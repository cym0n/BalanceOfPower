package BalanceOfPower::Player;

use strict;
use v5.10;

use Moo;
use BalanceOfPower::Constants ':all';

with 'BalanceOfPower::Role::Reporter';
with 'BalanceOfPower::Player::Role::Broker';
with 'BalanceOfPower::Player::Role::Hitman';


has name => (
    is => 'ro',
    default => 'Player'
);
has current_year => (
    is => 'rw'
);

sub dump
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
    print {$io} $indent . 
                join(";", $self->name, $self->money, $self->current_year) . "\n";
    print {$io} $indent . " " . "### WALLET\n";
    $self->dump_wallet($io, " " . $indent);            
    print {$io} $indent . " " . "### EVENTS\n";
    $self->dump_events($io, " " . $indent);
    print {$io} $indent . " " . "### TARGETS\n";
    $self->dump_targets($io, " " . $indent);
}

sub load
{
    my $self = shift;
    my $data = shift;
    my $world = shift;
    my @player_lines =  split /\n/, $data;
    my $player_line = shift @player_lines;
    $player_line =~ s/^\s+//;
    chomp $player_line;
    my ($name, $money, $current_year) = split ";", $player_line;
    my $what = '';
    my $extracted_data;
    my $wallet = {};
    my $targets = [];
    my $events = {};
    foreach my $line (@player_lines)
    {
        $line =~ s/^\s+//;
        chomp $line;
        if($line eq '### WALLET')
        {
            $what = 'wallet';
        }
        elsif($line eq '### EVENTS')
        {
            $what = 'events';
            $wallet = $self->load_wallet($extracted_data);
            $extracted_data = "";
        }
        elsif($line eq '### TARGETS')
        {
            $what = 'targets';
            $events = $self->load_events($extracted_data);
            $extracted_data = "";
        }
        else
        {
            $extracted_data .= $line . "\n";
        }
    }
    if($what eq 'targets')
    {
        $targets = $self->load_targets($extracted_data, $world);
    }
    elsif($what eq 'events')
    {
        $events = $self->load_events($extracted_data);
    }
    return $self->new(name => $name, money => $money, current_year => $current_year,
                      wallet => $wallet,
                      events => $events,
                      targets => $targets);
}



1;
