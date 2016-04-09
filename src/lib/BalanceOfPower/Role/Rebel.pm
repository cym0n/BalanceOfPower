package BalanceOfPower::Role::Rebel;

use strict;
use v5.10;
use Moo::Role;

use BalanceOfPower::CivilWar;
use BalanceOfPower::Constants ':all';

requires 'broadcast_event';
requires 'war_report';
requires 'lose_war';


has civil_wars => (
    is => 'rw',
    default => sub { [] }
);

sub get_civil_war
{
    my $self = shift;
    my $nation = shift;
    for(@{$self->civil_wars})
    {
        return $_ if $_->is_about($nation);
    }
    return undef;
}

sub start_civil_war
{
    my $self = shift;
    my $nation = shift;
    
    my $rebel_provinces = STARTING_REBEL_PROVINCES->[$nation->size];
    
    my $civwar = BalanceOfPower::CivilWar->new(nation => $nation,
                                               rebel_provinces => $rebel_provinces,
                                               current_year => $nation->current_year);
    $civwar->register_event("CIVIL WAR OUTBREAK!");
    $self->add_civil_war($civwar);
    $self->broadcast_event({ code => "civiloutbreak",
                             text => "CIVIL WAR OUTBREAK IN " . $nation->name, 
                             involved => [$nation->name] }, $nation->name);
    $self->war_report("Civil war in " . $nation->name . "!", $nation->name);
    $self->lose_war($nation->name, 1);
}

sub add_civil_war
{
    my $self = shift;
    my $civwar = shift;
    my $already = $self->get_civil_war($civwar->nation->name);
    if($already)
    {
        say "ERROR: Civil war in " . $civwar->nation->name . " already present!";
    }
    else
    {
        push @{$self->civil_wars}, $civwar;
    }
}
sub delete_civil_war
{
    my $self = shift;
    my $nation = shift;
    my @civwars = grep { $_->is_about($nation) } @{$self->civil_wars};
    $self->civil_wars(\@civwars);
}
sub civil_war_current_year
{
    my $self = shift;
    for(@{$self->civil_wars})
    {
        $_->current_year($self->current_year);
    }
}

sub at_civil_war
{
    my $self = shift;
    my $n = shift;
    if($self->get_civil_war($n))
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

1;


