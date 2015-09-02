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
has allowed_at_war => (
    is => 'ro',
    default => 0
);

sub allowed
{
    my $self = shift;
    return 0
        if($self->get_nation($self->player_nation)->internal_disorder_status() eq 'Civil war');
    if(! $self->allowed_at_war)
    {
        if($self->world->at_war($self->player_nation))
        {
            return 0;
        }
    }
    return 1;
}

sub extract_argument
{
    my $self = shift;
    my $query = shift;
    my $name = $self->name;
    if($query =~ /^$name( (.*))?$/)
    {
        return $2;
    }
    foreach my $syn (@{$self->synonyms})
    {
        if($query =~ /^$_( (.*))?/)
        {
            return $2;
        }
    }
    return undef;
}

sub recognize
{
    my $self = shift;
    my $query = shift;
    if(defined $self->extract_argument($query))
    {
        return 1;
    }
    else
    {
        return 0;
    }
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

1;
