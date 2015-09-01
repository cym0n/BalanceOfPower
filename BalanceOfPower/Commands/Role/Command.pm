package BalanceOfPower::Commands::Role::Command;

use strict;
use Moo::Role;

has name => (
    is => 'ro',
    default => 'DO NOTHING'
);

has world => (
    is => 'ro'
);
has synonyms => (
    is => 'rw',
    default => sub { [] }
);

sub recognize
{
    my $self = shift;
    my $query = shift;
    my $name = $self->name;
    return 1 if($query =~ /^$name/);
    foreach my $syn (@{$self->synonyms})
    {
        return 1 if($query =~ /^$_/);
    }
    return 0;
}

sub execute
{
    my $self = shift;
    my $query = shift;
    return $query;
}

sub print
{
    my $self = shift;
    return $self->name;
}
