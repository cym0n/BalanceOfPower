package BalanceOfPower::Role::Ruler;

use strict;
use Moo::Role;

use BalanceOfPower::Utils qw(prev_year next_year random random10 get_year_turns);
use BalanceOfPower::Constants ':all';

use BalanceOfPower::Relations::Influence;

requires 'broadcast_event';

has influences => (
    is => 'rw',
    default => sub { [] }
);

sub reset_influences
{
    my $self = shift;
    my $n1 = shift;
    @{$self->influences} = grep { ! $_->has_node($n1) } @{$self->influences};
}
sub influences_garbage_collector
{
    my $self = shift;
    @{$self->influences} = grep { ! $_->status == -1 } @{$self->influences};
}
sub is_under_influence
{
    my $self = shift;
    my $nation = shift;
    for(grep { $_->node2 eq $nation } @{$self->influences})
    {
        if(($_->status == 1 && $_->next != -1) ||
            $_->status > 1)
        {
            return $_->node1;
        }
    }
}
sub has_influence
{
    my $self = shift;
    my $nation = shift;
    my @out = ();
    for(grep { $_->node1 eq $nation } @{$self->influences})
    {
        if(($_->status == 1 && $_->next != -1) ||
            $_->status > 1)
        {
            push @out, $_->node1;
        }
    }
    return @out;
}
sub free_nation
{
    my $self = shift;
    my $nation = shift;
    $self->reset_influences($nation);
    $self->broadcast_event("$nation IS FREE!", $nation);
}
sub occupy
{
    my $self = shift;
    my $nation = shift;
    my $occupiers = shift;
    my $leader = shift;
    my $internal_disorder = shift || 0;
    $self->reset_influences($nation);
    foreach my $c (@{$occupiers})
    {
        if($c eq $leader)
        {
            push @{$self->influences}, BalanceOfPower::Relations::Influence->new( node1 => $c,
                                                                       node2 => $nation,
                                                                       status => 0,
                                                                       next => $internal_disorder ? 2 : 1,
                                                                       clock => 0 );
        }
        else
        {
            push @{$self->influences}, BalanceOfPower::Relations::Influence->new( node1 => $c,
                                                                       node2 => $nation,
                                                                       status => 0,
                                                                       clock => 0 );
        }
        $self->broadcast_event("$c OCCUPIES $nation", $c, $nation);
    }
}
sub situation_clock
{
    my $self = shift;
    foreach my $i (@{$self->influences})
    {
        my $old_status = $i->status_label;
        my $new_status = $i->click();    
        if($new_status && $old_status ne $new_status)
        {
            if($new_status eq 'dominate')
            {
                $self->broadcast_event($i->node1 . " DOMINATES " . $i->node2, $i->node1, $i->node2);
            }
            elsif($new_status eq 'control')
            {
                $self->broadcast_event($i->node1 . " CONTROLS " . $i->node2, $i->node1, $i->node2);
            }
        }
    }
    $self->influences_garbage_collector();
}

1;
