package BalanceOfPower::Targets::Role::Target;

use strict;
use v5.10;
use Moo::Role;

has target_obj => (
    is => 'ro',
);

has countdown => (
    is => 'rw',
);

sub click
{
    my $self = shift;
    $self->countdown($self->countdown -1);
    return $self->countdown == 0;
}
1;

