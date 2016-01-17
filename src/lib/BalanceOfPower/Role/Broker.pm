package BalanceOfPower::Role::Broker;

use strict;
use v5.10;
use Moo::Role;
use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw( prev_turn );

requires 'get_player';
requires 'get_nation';
requires 'get_statistics_value';

sub buy_stock
{
    my $self = shift;
    my $player = shift;
    my $nation = shift;
    my $q = shift;
    my $dry_run = shift || 0;
    my $player_obj = $self->get_player($player);
    my $nation_obj = $self->get_nation($nation);
    if($nation_obj->available_stocks < $q)
    {
        return { status => -11 };
    }
    if($self->at_civil_war($nation))
    {
        return { status => -14 };
    }
    return { status => 1,
             command => "buy $q $nation" } if $dry_run;
    my $unit_cost = $self->get_statistics_value(prev_turn($self->current_year), $nation, 'w/d');
    my $global_cost = $unit_cost * $q;
    my $influence = $q * STOCK_INFLUENCE_FACTOR;
    if($player_obj->money < $global_cost)
    {
        return { status => -12 };
    }
    $player_obj->add_money(-1 * $global_cost);
    $player_obj->add_stocks($q, $nation);
    $player_obj->add_influence($influence, $nation);
    $nation_obj->get_stocks($q);

    $player_obj->register_event("BOUGHT $q STOCKS OF $nation. COST: $global_cost ($unit_cost)");
    return { status => 1 };
}
sub sell_stock
{
    my $self = shift;
    my $player = shift;
    my $nation = shift;
    my $q = shift;
    my $dry_run = shift || 0;
    my $player_obj = $self->get_player($player);
    my $nation_obj = $self->get_nation($nation);
    if($player_obj->stocks($nation) < $q)
    {
        return { status => -13 };
    }
    if($self->at_civil_war($nation))
    {
        return { status => -14 };
    }
    return { status => 1,
             command => "sell $q $nation" } if $dry_run;
    my $unit_cost = $self->get_statistics_value(prev_turn($self->current_year), $nation, 'w/d');
    my $global_cost = $unit_cost * $q;
    $player_obj->add_money($global_cost);
    $player_obj->add_stocks(-1 * $q, $nation);
    $nation_obj->get_stocks(-1 * $q);
    $player_obj->register_event("SOLD $q STOCKS OF $nation. COST: $global_cost ($unit_cost)");
    return { status => 1 };
}
sub issue_war_bonds
{
    my $self = shift;
    my $n = shift;
    for(@{$self->players})
    {
        $_->issue_war_bonds($n);
    }
}
sub discard_war_bonds
{
    my $self = shift;
    my $nation = shift;
    for(@{$self->players})
    {
        $_->discard_war_bonds($nation);
    }
}
sub empty_stocks
{
    my $self = shift;
    my $nation = shift;
    for(@{$self->players})
    {
        $_->empty_stocks($nation);
    }
}
sub cash_war_bonds
{
    my $self = shift;
    my $nation = shift;
    for(@{$self->players})
    {
        $_->cash_war_bonds($nation);
    }
}

1;
