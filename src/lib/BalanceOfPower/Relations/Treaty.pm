package BalanceOfPower::Relations::Treaty;

use strict;
use v5.10;

use Moo;

with 'BalanceOfPower::Relations::Role::Relation';

has '+rel_type' => (
    is => 'ro',
    default => 'treaty'
);

has 'type' => (
    is => 'ro',
);

around 'print' => sub {
    my $orig = shift;
    my $self = shift;
    return $self->short_tag . ": " .
           $self->$orig();
};

sub short_tag 
{
    my $self = shift;
    if($self->type eq 'alliance')
    {
        return 'ALL';
    }
    elsif($self->type eq 'no aggression')
    {
        return 'NAG';
    }
    elsif($self->type eq 'commercial')
    {
        return 'COM';
    }
    else
    {
        return '???';
    }

}
sub dump
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
    print {$io} $indent . join(";", $self->node1, $self->node2, $self->type) . "\n";
}
sub to_mongo
{
    my $self = shift;
    return {
             rel_type => $self->rel_type, 
             node1 => $self->node1,
             node2 => $self->node2,
             type => $self->type,
    }
}
sub load
{
    my $self = shift;
    my $data = shift;
    $data =~ s/^\s+//;
    chomp $data;
    my ($node1, $node2, $type) = split ";", $data;
    return $self->new(node1 => $node1, node2 => $node2, type => $type);
}

1;
