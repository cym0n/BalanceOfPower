package BalanceOfPower::Player;

use strict;
use v5.10;

use Moo;
use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw(as_title);

with 'BalanceOfPower::Role::Reporter';

has name => (
    is => 'ro',
    default => 'Player'
);

has money => (
    is => 'rw',
    default => 0
);

has wallet => (
    is => 'ro',
    default => sub { {} }
);

has current_year => (
    is => 'rw'
);
has stock_orders => (
    is => 'rw',
    default => sub { [] }
);
has control_orders => (
    is => 'rw',
    default => sub { {} }
);

sub init_nation_wallet
{
    my $self = shift;
    my $nation = shift;
    $self->wallet->{$nation}->{'stocks'} = 0;
    $self->wallet->{$nation}->{'influence'} = 0;
    $self->wallet->{$nation}->{'war bonds'} = 0;
}
sub add_wallet_element
{
    my $self = shift;
    my $element = shift;
    my $nation = shift;
    my $q = shift;
    if(exists $self->wallet->{$nation})
    {
        $self->wallet->{$nation}->{$element} += $q;
    }
    else
    {
        $self->init_nation_wallet($nation);
        $self->wallet->{$nation}->{$element} = $q;
    }
}
sub get_wallet_element
{
    my $self = shift;
    my $element = shift;
    my $nation = shift;
    if(exists $self->wallet->{$nation})
    {
        return $self->wallet->{$nation}->{$element};
    }
    else
    {
        return 0;
    }
}

sub add_stocks
{
    my $self = shift;
    my $q = shift;
    my $nation = shift;
    $self->add_wallet_element('stocks', $nation, $q);
}
sub stocks
{
    my $self = shift;
    my $nation = shift;
    $self->get_wallet_element('stocks', $nation);
}
sub influence
{
    my $self = shift;
    my $nation = shift;    
    $self->get_wallet_element('influence', $nation);
}
sub add_influence
{
    my $self = shift;
    my $q = shift;
    my $nation = shift;
    $self->add_wallet_element('influence', $nation, $q);
}
sub add_war_bonds
{
    my $self = shift;
    my $nation = shift;
    $self->add_wallet_element('war bonds', $nation, 1);
}
sub war_bonds
{
    my $self = shift;
    my $nation = shift;    
    $self->get_wallet_element('war bonds', $nation);
}
sub add_money
{
    my $self = shift;
    my $q = shift;
    $self->money($self->money + $q);
    $self->money(0) if($self->money < 0);
}
sub issue_war_bonds
{
    my $self = shift;
    my $nation = shift;
    if($self->stocks($nation) > 0 && $self->money > WAR_BOND_COST)
    {
        $self->add_money(-1 * WAR_BOND_COST);
        $self->add_war_bonds($nation);
        $self->register_event("WAR BOND FOR $nation ISSUED. PAYED " . WAR_BOND_COST);
    }
    else
    {
        $self->register_event("WAR BOND FOR $nation NOT ISSUED. NOT ENOUGH MONEY");
    }
}
sub discard_war_bonds
{
    my $self = shift;
    my $nation = shift;
    if($self->war_bonds($nation) > 0)
    {
        $self->wallet->{$nation}->{'war bonds'} = 0;
        $self->register_event("WAR LOST FOR $nation! WAR BONDS FROM $nation HAVE NOW NO VALUE");
    }
}
sub cash_war_bonds
{
    my $self = shift;
    my $nation = shift;
    if($self->war_bonds($nation) > 0)
    {
        my $gain = $self->wallet->{$nation}->{'war bonds'} * WAR_BOND_GAIN;
        $self->add_money($gain);
        $self->wallet->{$nation}->{'war bonds'} = 0;
        $self->register_event("WAR WON FOR $nation! GAINES $gain FROM WAR BONDS");

    }
}
sub empty_stocks
{
    my $self = shift;
    my $nation = shift;
    if($self->stocks($nation) > 0)
    {
        $self->wallet->{$nation}->{'stocks'} = 0;
        $self->wallet->{$nation}->{'war bonds'} = 0;
        $self->wallet->{$nation}->{'influence'} = 0;
    }
    $self->register_event("INVESTMENTS IN $nation LOST BECAUSE OF REVOLUTION!");
}
sub add_stock_order
{
    my $self = shift;
    my $order = shift;
    push @{$self->stock_orders}, $order;
}
sub remove_stock_orders
{
    my $self = shift;
    my $nation = shift;
    my @ords = grep { $_ !~ /$nation/ } @{$self->stock_orders}; 
    $self->stock_orders(\@ords);
}
sub empty_stock_orders
{
    my $self = shift;
    $self->stock_orders([]);
}
sub print_stock_orders
{
    my $self = shift;
    my $out = as_title("STOCK ORDERS");
    $out .= "\n\n";
    foreach my $ord (@{$self->stock_orders})
    {
        $out .= $ord . "\n";
    }
    return $out;
}

sub add_control_order
{
    my $self = shift;
    my $nation = shift;
    my $order = shift;
    $self->control_orders->{$nation} = $order;
}
sub get_control_order
{
    my $self = shift;
    my $nation = shift;
    if(exists $self->control_orders->{$nation})
    {
        return $self->control_orders->{$nation};
    }
    else
    {
        return undef;
    }
}
sub remove_control_order
{
    my $self = shift;
    my $nation = shift;
    $self->control_orders->{$nation} = undef;
}
sub print_control_orders
{
    my $self = shift;
    my $out = as_title("CONTROL ORDERS");
    $out .= "\n\n";
    for(keys %{$self->control_orders})
    {
        my $n = $_;
        $out .= $n . ": " . $self->get_control_order($n) . "\n";
    }
    return $out;
}



1;
