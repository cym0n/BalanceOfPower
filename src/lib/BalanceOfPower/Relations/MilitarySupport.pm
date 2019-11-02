package BalanceOfPower::Relations::MilitarySupport;

use strict;
use v5.10;

use Moo;

with 'BalanceOfPower::Relations::Role::Relation';

has '+rel_type' => (
    is => 'ro',
    default => 'support'
);
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
sub to_mongo
{
    my $self = shift;
    return { rel_type => $self->rel_type,
             node1 => $self->node1,
             node2 => $self->node2,
             army => $self->army,
    }
}
sub load
{
    my $self = shift;
    my $data = shift;
    $data =~ s/^\s+//;
    chomp $data;
    my ($node1, $node2, $army) = split ";", $data;
    return $self->new(node1 => $node1, node2 => $node2, army => $army);
}




1;
