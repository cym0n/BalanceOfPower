package BalanceOfPower::Role::Rebel;

use strict;
use v5.10;
use Moo::Role;

use BalanceOfPower::CivilWar;
use BalanceOfPower::Constants ':all';

requires 'broadcast_event';
requires 'war_report';
requires 'lose_war';
requires 'supported';


has civil_wars => (
    is => 'rw',
    default => sub { [] }
);

has civil_memorial => (
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
                                               start_date => $nation->current_year,
                                               mongo_save => $self->mongo_save,
                                               mongo_runtime_db => 'bop_' . $self->name . '_runtime',
                                               log_active => 0,
                                            );
    $self->add_civil_war($civwar);
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
        $civwar->register_event({ code => "civwarstartarmy",
                                  text => "Starting army: " . $civwar->nation->army,
                                  involved => [$civwar->nation->name],
                                  values => [$civwar->nation->army] });
        my $sup = $self->supported($civwar->nation->name);
        if($sup)
        {
            $civwar->register_event({ code => "civwargovsupport",
                                      text => "Support to government from " . $sup->node1,
                                      involved => [$civwar->nation->name, $sup->node1],
                                      values => []});
        }
        my $e = { code => "civiloutbreak",
                                text => "CIVIL WAR OUTBREAK IN " . $civwar->nation->name, 
                                involved => [$civwar->nation->name] };
        $self->broadcast_event($e, $civwar->nation->name);
        $self->war_report($e, $civwar->nation->name);
        my $occupied = $self->lose_war($civwar->nation->name, 1);
        if(! $occupied)
        {
            $self->_add_civil_war($civwar);
        }
    }
}
sub _add_civil_war
{
    my $self = shift;
    my $civwar = shift;
    push @{$self->civil_wars}, $civwar;
}
sub delete_civil_war
{
    my $self = shift;
    my $nation = shift;
    my $cw = $self->get_civil_war($nation);
    if($cw)
    {
        $cw->end_date($self->current_year);
        
        push @{$self->civil_memorial}, $cw;
        $self->to_mongo_memorial("civil war", $cw) if $self->mongo_save;
    }
    my @civwars = grep { ! $_->is_about($nation) } @{$self->civil_wars};
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

sub dump_civil_memorial
{
    my $self = shift;
    my $io = shift;
    my $indent = shift;
    foreach my $cw (@{$self->civil_memorial})
    {
        print {$io} $cw->dump($io, $indent);
    }
}
sub load_civil_memorial
{
    my $self = shift;
    my $data = shift;
    
    $data .= "EOF";
    my $war_data = "";
    my @memorial;
    my @lines = split "\n", $data;
    foreach my $l (@lines)
    {
        if($l !~ /^\s/)
        {
            if($war_data)
            {
                my $cw = BalanceOfPower::CivilWar->load($war_data);
                $cw->load_nation($self);
                push @memorial, $cw;
                $war_data = $l . "\n";
            }
            else
            {
                $war_data = $l . "\n";
            }
        }
        else
        {
            $war_data .= $l . "\n";
        }
    }
    return \@memorial;
}


1;


