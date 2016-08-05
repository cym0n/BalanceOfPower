package BalanceOfPower::Role::Shopper;

use strict;
use v5.10;
use Moo::Role;
use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw( prev_turn );
use BalanceOfPower::Printer;

use Data::Dumper;

requires 'order_statistics';
requires 'get_statistics_value';


my @products = ( 'goods', 'luxury', 'arms', 'tech', 'culture' );

sub calculate_price
{
    my $self = shift;
    my $y = shift;
    my $value = shift;
    my $nation = shift;


    my %dependencies = ( 'goods' => 'p/d',
                          'luxury' => 'w/d', 
                          'arms' => 'army',
                          'tech' => 'progress',
                          'culture' => 'prestige' );

    #Price formula is MaxValue/NationValue * FACTOR

    my $turn = $value eq 'goods' || $value eq 'prestige' ? $y : prev_turn($y);
    my @stat_values = $self->order_statistics($turn, $dependencies{$value});
    return SHOP_PRICE_FACTOR if(@stat_values == 0);
    my $max_value = $stat_values[0]->{'value'};
    return SHOP_PRICE_FACTOR if($max_value == 0);

    my $nation_value = $self->get_statistics_value($turn, $nation, $dependencies{$value});
    $nation_value ||= 1;
    return int((($max_value / $nation_value) * SHOP_PRICE_FACTOR) *100)/100;
}
    
sub get_all_nation_prices
{
    my $self = shift;
    my $nation = shift;
    my $year = shift;
    my %data = ();
    foreach my $p (@products)
    {
        my $label = $p . "_price";
        $data{$label} = $self->calculate_price($year, $p, $nation);
    }
    return %data;
}

sub print_nation_shop_prices
{
    my $self = shift;
    my $y = shift;
    my $nation = shift;
    my $mode = shift || 'print';
    my %data = $self->get_all_nation_prices($nation, $y);
    $data{nation} = $nation;
    return BalanceOfPower::Printer::print($mode, $self, 'print_shop_prices', \%data); 
}

sub print_all_nations_prices
{
    my $self = shift;
    my $y = shift;
    my $mode = shift || 'print';
    my @nations = @{$self->nation_names};
    my %data = ();
    foreach my $n (@nations)
    {
        my %prices = $self->get_all_nation_prices($n, $y); 
        $data{$n} = \%prices;
    }
    return BalanceOfPower::Printer::print($mode, $self, 'print_all_shop_prices', 
                                                { prices => \%data,
                                                  names => \@nations }); 
}

sub do_transaction
{
    my $self = shift;
    my $player = shift;
    my $action = shift;
    my $q = shift;
    my $what = shift;
    if(! grep {$_ eq $what} @products)
    {
        return -10;
    }
    my $price = $self->calculate_price($self->current_year, $what, $player->position);
    my $cost = $price * $q;
    if($action eq 'buy')
    {   
        if($cost > $player->money)
        {
            return -11;
        }
        if($q > $player->cargo_free_space)
        {
            return -12;
        }
        $player->add_money(-1 * $cost);
        $player->add_cargo($what, $q);
    }
    elsif($action eq 'sell')
    {
        my $have = $player->get_cargo($what);
        if($have < $q)
        {
            return -13;
        }
        $player->add_money($cost);
        $player->add_cargo($what, -1 * $q);
    }
    return (1, $cost);
}

