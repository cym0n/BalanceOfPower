package BalanceOfPower::Relations::Treaty;

use strict;
use v5.10;

use Moo;

with 'BalanceOfPower::Relations::Role::Relation';

has type => (
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

1;
