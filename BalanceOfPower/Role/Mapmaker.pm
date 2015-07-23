package BalanceOfPower::Role::Mapmaker;

use strict;
use Moo::Role;

use BalanceOfPower::Border;

has borders => (
    is => 'rw',
    default => sub { [] }
);

sub load_borders
{
    my $self = shift;
    my $file = shift || "data/borders.txt";
    open(my $borders, "<", $file) || die $!;;
    for(<$borders>)
    {
        chomp;
        my @nodes = split(/,/, $_);
        if($nodes[0] && $nodes[1] && ! $self->border_exists($nodes[0], $nodes[1]))
        {
            my $b = BalanceOfPower::Border->new(node1 => $nodes[0], node2 => $nodes[1]);
            push @{$self->borders}, $b;
        }
    }
}
sub border_exists
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    foreach my $r (@{$self->borders})
    {
        return 1 if($r->is_between($node1, $node2));
    }
    return 0;
}
sub print_borders
{
    my $self = shift;
    my $n = shift;
    my $out;
    foreach my $b (@{$self->borders})
    {
        if($b->has_node($n))
        {
            $out .= $b->print($n) . "\n";
        }
    }
    return $out;
}

1;
