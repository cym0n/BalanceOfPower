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


    my %dependencies = ( 'goods' => 'production',
                          'luxury' => 'wealth', #previous year
                          'arms' => 'army',
                          'tech' => 'progress',
                          'culture' => 'prestige' );

    #Price formula is MaxValue/NationValue * FACTOR

    my $turn = $value eq 'goods' || $value eq 'prestige' ? $y : prev_turn($y);
    my @stat_values = $self->order_statistics($turn, $dependencies{$value});
    my $max_value = $stat_values[0]->{'value'};
    return SHOP_PRICE_FACTOR if($max_value == 0);

    my $nation_value = $self->get_statistics_value($turn, $nation, $dependencies{$value});
    $nation_value ||= 1;
    return int((($max_value / $nation_value) * SHOP_PRICE_FACTOR) *100)/100;
}

sub print_nation_shop_prices
{
    my $self = shift;
    my $y = shift;
    my $nation = shift;
    my $mode = shift || 'print';
    my $data = {};
    foreach my $p (@products)
    {
        my $label = $p . "_price";
        $data->{$label} = $self->calculate_price($y, $p, $nation);
    }
    return BalanceOfPower::Printer::print($mode, $self, 'print_shop_prices', $data); 
}

