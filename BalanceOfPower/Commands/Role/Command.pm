package BalanceOfPower::Commands::Role::Command;

use strict;
use v5.10;
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
        if($self->world->get_nation($self->world->player_nation)->internal_disorder_status() eq 'Civil war');
    if(! $self->allowed_at_war)
    {
        if($self->world->at_war($self->world->player_nation))
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
    my $extract = shift;
    $extract =1 if(! defined $extract);
    my $name = $self->name;
    if($query =~ /^$name( (.*))?$/)
    {
        if($extract)
        {
            return $2;
        }
        else
        {
            return 1;
        }
    }
    foreach my $syn (@{$self->synonyms})
    {
        if($query =~ /^$syn( (.*))?/)
        {
            if($extract)
            {
                return $2;
            }
            else
            {
                return 1;
            }
        }
    }
    return undef;
}

sub recognize
{
    my $self = shift;
    my $query = shift;
    if($self->extract_argument($query, 0))
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
    return { status => 1, command => $query };
}

sub print
{
    my $self = shift;
    return $self->name;
}

1;