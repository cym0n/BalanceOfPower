package BalanceOfPower::CivilWar;

use strict;
use v5.10;

use Moo;
use BalanceOfPower::Constants ':all';

with 'BalanceOfPower::Role::Reporter';

has nation => (
    is => 'rw',
);
has nation_to_load => (
    is => 'rw',
);
has rebel_provinces => (
    is => 'rw',
    default => 0
);
has current_year => (
    is => 'rw'
);

sub name
{
    my $self = shift;
    return "Civil war in " . $self->nation->name;
}
sub nation_name 
{
    my $self = shift;
    return $self->nation->name;
}

sub is_about
{
    my $self = shift;
    my $nation = shift;
    return $self->nation->name eq $nation;
}

sub fight
{
    my $self = shift;
    my $world = shift;
    my $government = $world->random(0, 100, $self->name . ": government fight result");
    my $rebels = $world->random(0, 100, $self->name . ": rebels fight result");
    $self->nation->register_event("FIGHTING CIVIL WAR");
    if($self->nation->army >= ARMY_UNIT_FOR_CIVIL_WAR)
    {
        $self->nation->add_army(-1 * ARMY_UNIT_FOR_CIVIL_WAR);
        $government += ARMY_HELP_FOR_CIVIL_WAR;
        $self->register_event("HELP FROM ARMY FOR GOVERNMENT");
    }
    if($self->nation->government eq 'dictatorship')
    {
        $government += DICTATORSHIP_BONUS_FOR_CIVIL_WAR;
        $self->register_event("HELP FROM DICTATORSHIP FOR GOVERNMENT");
    }
    my $reb_sup;
    my $sup;
    if($reb_sup = $world->rebel_supported($self->nation_name))
    {
        $rebels += REBEL_SUPPORT_HELP_FOR_CIVIL_WAR;
        $self->register_event("HELP FROM REBEL SUPPORT FOR REBELS");
    }
    if($sup = $world->supported($self->nation_name))
    {
        $government += SUPPORT_HELP_FOR_CIVIL_WAR;
        $self->register_event("HELP FROM SUPPORT FOR GOVERNMENT");
    }
    if($reb_sup)
    {
        $world->change_diplomacy($self->nation_name, $reb_sup->node1, -1 * DIPLOMACY_MALUS_FOR_REBEL_CIVIL_WAR_SUPPORT, uc($self->name));
    }
    if($sup && $reb_sup)
    {
        $world->change_diplomacy($sup->node1, $reb_sup->node1, -1 * DIPLOMACY_MALUS_FOR_CROSSED_CIVIL_WAR_SUPPORT, uc($self->name));
    }
    if($government > $rebels)
    {
        $reb_sup->casualities(1) if $reb_sup;
        $world->rebel_military_support_garbage_collector();
        $self->register_event("BATTLE WON BY GOVERNMENT [G: $government - R: $rebels]");
        return $self->battle('government', $world);
    }
    elsif($rebels > $government)
    {
        $sup->casualities(1) if $sup;
        $world->military_support_garbage_collector();
        $self->register_event("BATTLE WON BY REBELS [G: $government - R: $rebels]");
        return $self->battle('rebels', $world);
    }
    else
    {
        return undef;
    }
}
sub battle
{
    my $self = shift;
    my $battle_winner = shift;
    my $world = shift;
    if($battle_winner eq 'government')
    {
        $self->rebel_provinces($self->rebel_provinces() - .5);
    }
    elsif($battle_winner eq 'rebels')
    {
        $self->rebel_provinces($self->rebel_provinces() + .5);
    }
    $self->register_event("REBEL PROVINCES: " . $self->rebel_provinces());
    if($self->rebel_provinces == 0)
    {
        $self->nation->internal_disorder(AFTER_CIVIL_WAR_INTERNAL_DISORDER);
        $self->register_event("THE GOVERNMENT WON THE CIVIL WAR");
        $world->broadcast_event( { code => 'govwincivil',
                                   text => "THE GOVERNMENT OF " . $self->nation_name . " WON THE CIVIL WAR",
                                   involved => [$self->nation_name] }, $self->nation_name );
        return 'government';
    }
    elsif($self->rebel_provinces == PRODUCTION_UNITS->[$self->nation->size])
    {
        $self->nation->internal_disorder(AFTER_CIVIL_WAR_INTERNAL_DISORDER);
        $self->register_event("THE REBELS WON THE CIVIL WAR");
        $world->broadcast_event( { code => 'rebwincivil',
                                   text => "THE REBELS IN " . $self->nation_name . " WON THE CIVIL WAR",
                                   involved => [$self->nation_name] }, $self->nation_name );
      
        return 'rebels';
    }
    return undef;
}

sub win
{
    my $self = shift;
    my $winner = shift;
    my $world = shift;
    if($winner eq 'rebels')
    {
        $self->nation->new_government($world);
        my $rebsup = $world->rebel_supported($self->nation_name);
        if($rebsup)
        {
            my $rebel_supporter = $world->get_nation($rebsup->node1);
            $world->stop_rebel_military_support($rebel_supporter, $self) if $rebel_supporter;
            $world->diplomacy_exists($self->nation_name, $rebel_supporter->name)->factor(REBEL_SUPPORTER_WINNER_FRIENDSHIP);
            $world->create_treaty($self->nation_name, $rebel_supporter->name, 'alliance');
            $world->broadcast_event({ code => 'alliancetreatynew',
                                     text => "ALLIANCE BETWEEN " . $self->nation_name . " AND " . $rebel_supporter->name, 
                                     involved => [$self->nation_name, $rebel_supporter->name],
                                     values => ['rebsup'] }, $self->nation_name, $rebel_supporter->name);
        }
        $world->empty_stocks($self->nation_name);
        $self->nation->available_stocks(START_STOCKS->[$self->nation->size]);
    }
    elsif($winner eq 'government')
    {
        my $rebsup = $world->rebel_supported($self->nation_name);
        if($rebsup)
        {
            my $rebel_supporter = $world->get_nation($rebsup->node1);
            $world->stop_rebel_military_support($rebel_supporter, $self->nation) if $rebel_supporter;
        }
    }  
}
sub dump
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
    print {$io} $indent . 
                join(";", $self->nation_name, $self->rebel_provinces, $self->current_year) . "\n";
    $self->dump_events($io, " " . $indent);
}
sub load
{
    my $self = shift;
    my $data = shift;
    my $cw_line = ( split /\n/, $data )[0];
    $cw_line =~ s/^\s+//;
    chomp $cw_line;
    my ($nation, $rebel_provinces, $current_year) = split ";", $cw_line;
    $data =~ s/^.*?\n//;
    my $events = $self->load_events($data);
    return $self->new( nation_to_load => $nation, rebel_provinces => $rebel_provinces, current_year => $current_year);
}
sub load_nation
{
    my $self = shift;
    my $world = shift;
    $self->nation($world->get_nation($self->nation_to_load));
}




1;

