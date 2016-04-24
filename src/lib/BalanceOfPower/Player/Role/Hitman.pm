package BalanceOfPower::Player::Role::Hitman;

use strict;
use v5.10;
use Moo::Role;

use BalanceOfPower::Constants ':all';



has targets => (
    is => 'rw',
    default => sub { [] }
);
has mission_points => (
    is => 'rw',
    default => 0
);


sub no_targets
{
    my $self = shift;
    return @{$self->targets} <= 0;
}
sub add_target
{
    my $self = shift;
    my $target = shift;
    push @{$self->targets}, $target;
}
sub check_targets
{
    my $self = shift;
    my $world = shift;
    my @not_achieved = ();
    for( @{$self->targets})
    {
        my $t = $_;
        if($t->achieved($self))
        {
            $self->point;
            $self->register_event("ACHIEVED TARGET: " . $t->name);
        }
        else
        {
            push @not_achieved, $t;
        }
    }
    $self->targets(\@not_achieved);
}
sub click_targets
{
    my $self = shift;
    my $world = shift;
    my @not_passed = ();
    for( @{$self->targets})
    {
        my $t = $_;
        if($t->click)
        {
            $self->register_event("TIME EXPIRED FOR TARGET: " . $t->name);
        }
        else
        {
            push @not_passed, $t;
        }
    }
    $self->targets(\@not_passed);
}
sub point
{
    my $self = shift;
    $self->mission_points($self->mission_points + 1);
}

1;



