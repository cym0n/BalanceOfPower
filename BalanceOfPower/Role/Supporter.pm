package BalanceOfPower::Role::Supporter;

use strict;
use v5.10;
use Moo::Role;

use BalanceOfPower::Relations::MilitarySupport;
use BalanceOfPower::Constants ':all';

requires 'get_nation';

has military_supports => (
    is => 'ro',
    default => sub { BalanceOfPower::Relations::RelPack->new() },
    handles => { add_military_support => 'add_link',
                 delete_military_support => 'delete_link',
                 exists_military_support => 'exists_link',
                 already_in_military_support => 'first_link_for_node',
                 supports => 'links_for_node',
                 supporter => 'links_for_node1',
                 supported => 'links_for_node2',
                 print_military_supports => 'print_links',
                 reset_supports => 'delete_link_for_node'
               }
);

sub start_military_support
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    return 0 if($nation1->army < ARMY_FOR_SUPPORT);
    return 0 if($self->supporter($nation2->name));
    my @supported = $self->supported($nation1->name);
    if(@supported)
    {
        for(@supported) #should always be just one record
        {
            $self->stop_military_support($self->get_nation($_->node1), $self->get_nation($_->node2));
        } 
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
sub stop_military_support
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    my $milsup = $self->exists_military_support($node1->name, $node2->name);
    return if (! $milsup);
    $self->delete_military_support($node1->name, $node2->name);
    $node1->add_army($milsup->army);
    $self->broadcast_event("MILITARY SUPPORT FROM " . $node1->name . " STOPPED BY " . $node2->name, $node1->name, $node2->name);
    $self->change_diplomacy($node1->name, $node2->name, -1 * DIPLOMACY_FACTOR_BREAKING_SUPPORT);
}
sub military_support_garbage_collector
{
    my $self = shift;
    $self->influences->garbage_collector(sub { my $rel = shift; return $rel->army <= 0 });
}

1;
