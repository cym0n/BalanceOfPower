package BalanceOfPower::Relations::MilitarySupport;

use strict;
use v5.10;

use Moo;

with 'BalanceOfPower::Relations::Role::Relation';

has army => (
    is => 'rw',
    default => 0
);


sub bidirectional
{
    return 0;
}

sub casualities
{
    my $self = shift;
    my $casualities = shift;
    $self->army($self->army - $casualities);
    $self->army(0) if($self->army < 0);
}

sub print 
{
    my $self = shift;
    return $self->node1 . " --> " . $self->node2 . " [" . $self->army . "]";
}
sub dump
{
    my $self = shift;
    my $io = shift;
    my $indent = shift;
    print {$io} $indent . join(";", $self->node1, $self->node2, $self->army) . "\n";
}



1;
