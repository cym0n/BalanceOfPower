package BalanceOfPower::Commands::TargetNation;

use Moo;
use v5.10;
use IO::Prompter;
use Data::Dumper;


with "BalanceOfPower::Commands::Role::Command";

has exclude_player_nation => (
    is => 'rw',
    default => 1
);

sub select_message
{
    return "Select a nation:";
}

sub execute
{
    my $self = shift;
    my $query = shift;
    my $nation = shift;
    if($self->good_target($nation))
    {
        return { status => 1, command => $self->name . " " . $nation };
    }
    my $argument = $self->extract_argument($query);
    if($argument)
    {
        if($self->good_target($argument))
        {
            return { status => 1, command => $self->name . " " . $argument };
        }
        else
        {
            say "Bad argument provided: $argument";
        }
    }
    my @nations = $self->get_available_targets;
    if(@nations > 0)
    {
        $nation = prompt $self->select_message, -menu=>\@nations;
        return { status => 1, command => $self->name . " " . $nation };
    }
    else
    {
        return { status => -2 };
    }
}

sub good_target
{
    my $self = shift;
    my $nation = shift;
    my @nations = $self->get_available_targets();
    my @selected = grep { $_ eq $nation} @nations;
    if(@selected >= 1)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

sub get_available_targets
{
    my $self = shift;
    my @nations = @{$self->world->nation_names};
    if($self->exclude_player_nation)
    {
        @nations = grep { $_ ne $self->world->player_nation } @nations;
    }
    return @nations
}

1;
