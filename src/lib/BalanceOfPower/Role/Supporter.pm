package BalanceOfPower::Role::Supporter;

use strict;
use v5.10;
use Moo::Role;

use BalanceOfPower::Relations::MilitarySupport;
use BalanceOfPower::Constants ':all';

requires 'get_nation';
requires 'at_civil_war';

has military_supports => (
    is => 'ro',
    default => sub { BalanceOfPower::Relations::RelPack->new() },
    handles => { add_military_support => 'add_link',
                 delete_military_support => 'delete_link',
                 exists_military_support => 'exists_link',
                 already_in_military_support => 'first_link_for_node',
                 supports => 'links_for_node',
                 supporter => 'links_for_node1',
                 supported => 'first_link_for_node2',
                 print_military_supports => 'print_links',
                 reset_supports => 'delete_link_for_node'
               }
);
has rebel_military_supports => (
    is => 'ro',
    default => sub { BalanceOfPower::Relations::RelPack->new() },
    handles => { add_rebel_military_support => 'add_link',
                 delete_rebel_military_support => 'delete_link',
                 exists_rebel_military_support => 'exists_link',
                 rebel_supporter => 'links_for_node1',
                 rebel_supported => 'first_link_for_node2',
                 print_rebel_military_supports => 'print_links',
                 reset_rebel_supports => 'delete_link_for_node'
               }
);

sub start_military_support
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    return 0 if($nation1->army < ARMY_FOR_SUPPORT);
    return 0 if($self->supporter($nation2->name));
    my $supported = $self->supported($nation1->name);
    if($supported)
    {
            $self->stop_military_support($self->get_nation($supported->node1), $self->get_nation($supported->node2));
    }
    $nation1->add_army(-1 * ARMY_FOR_SUPPORT);
    $self->add_military_support(
        BalanceOfPower::Relations::MilitarySupport->new(
            node1 => $nation1->name,
            node2 => $nation2->name,
            army => ARMY_FOR_SUPPORT));
    $self->broadcast_event("MILITARY SUPPORT TO " . $nation2->name . " STARTED BY " . $nation1->name, $nation1->name, $nation2->name);
    $self->change_diplomacy($nation1->name, $nation2->name, DIPLOMACY_FACTOR_STARTING_SUPPORT);
}
sub start_rebel_military_support
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    return 0 if($nation1->army < REBEL_ARMY_FOR_SUPPORT);
    return 0 if(! $self->at_civil_war($nation2->name));
    $nation1->add_army(-1 * ARMY_FOR_SUPPORT);
    $self->add_rebel_military_support(
        BalanceOfPower::Relations::MilitarySupport->new(
            node1 => $nation1->name,
            node2 => $nation2->name,
            army => ARMY_FOR_SUPPORT));
    $self->broadcast_event("REBEL MILITARY SUPPORT AGAINST " . $nation2->name . " STARTED BY " . $nation1->name, $nation1->name, $nation2->name);
    $self->change_diplomacy($nation1->name, $nation2->name, DIPLOMACY_FACTOR_STARTING_REBEL_SUPPORT);
}
sub stop_military_support
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    my $milsup = $self->exists_military_support($node1->name, $node2->name);
    return if (! $milsup);
    $self->delete_military_support($node1->name, $node2->name);
    $node1->add_army($milsup->army);
    $self->broadcast_event("MILITARY SUPPORT FOR " . $node2->name . " STOPPED BY " . $node1->name, $node1->name, $node2->name);
    $self->change_diplomacy($node1->name, $node2->name, -1 * DIPLOMACY_FACTOR_BREAKING_SUPPORT);
}
sub military_support_garbage_collector
{
    my $self = shift;
    $self->military_supports->garbage_collector(sub { my $rel = shift; return $rel->army <= 0 });
}
sub rebel_military_support_garbage_collector
{
    my $self = shift;
    $self->rebel_military_supports->garbage_collector(sub { my $rel = shift; return $rel->army <= 0 });
}

1;
