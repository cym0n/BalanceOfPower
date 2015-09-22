package BalanceOfPower::Role::Logger;

use strict;
use v5.10;
use Moo::Role;

use Cwd;

has log_active => (
    is => 'rw',
    default => 1
);

has log_name => (
    is => 'rw',
    default => "bop.log"
);

has log_dir => (
    is => 'rw',
    default => sub { getcwd }
);

sub log_path
{
    my $self = shift;
    return $self->log_dir . "/" .$self->log_name;
}

sub log
{
    my $self = shift;
    return if(! $self->log_active);
    my $message = shift;
    open(my $log, ">>", $self->log_path);
    print $log $message . "\n";
    close($log);
}

sub delete_log
{
    my $self = shift;
    unlink $self->log_path;
}

1;
