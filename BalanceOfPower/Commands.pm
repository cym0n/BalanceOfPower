package BalanceOfPower::Commands;

use Moo;

has commands => (
    is => 'rw',
    default => sub { [] }
);

sub init
{
    my $self = shift;
    my $world = shift;
    my $command = BalanceOfPower::Commands::Plain->new( name => "BUILD TROOPS",
                                                        world => $world );
    push @{$self->commands}, $command; 
    $command = BalanceOfPower::Commands::Plain->new( name => "LOWER DISORDER",
                                                     world => $world );
    push @{$self->commands}, $command; 
    $command = BalanceOfPower::Commands::Plain->new( name => "ADD ROUTE",
                                                     world => $world );
    push @{$self->commands}, $command; 

}
