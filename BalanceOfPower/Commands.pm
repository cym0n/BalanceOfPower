package BalanceOfPower::Commands;

use Moo;

has commands => (
    is => 'rw',
    default => sub { [] }
);

has query => (
    is => 'rw',
    default => undef
);

has nation => (
    is => 'rw',
    default => undef
);

has active => (
    is => 'rw',
    default => 1
);

sub init
{
    my $self = shift;
    my $world = shift;
    my $command = 
        BalanceOfPower::Commands::Plain->new( name => "BUILD TROOPS",
                                              world => $world,
                                              allowed_at_war => 1 );
    push @{$self->commands}, $command; 
    $command = 
        BalanceOfPower::Commands::Plain->new( name => "LOWER DISORDER",
                                              world => $world );
    push @{$self->commands}, $command; 
    $command = 
        BalanceOfPower::Commands::Plain->new( name => "ADD ROUTE",
                                              world => $world );
    push @{$self->commands}, $command; 
    $command =
        BalanceOfPower::Commands::DeclareWar-> ( name => "DECLARE WAR TO",
                                                 synonyms => ["DECLARE WAR"],
                                                 world => $world );
    push @{$self->commands}, $command; 
    $command =
        BalanceOfPower::Commands::TargetRoute-> ( name => "DELETE TRADEROUTE",
                                                 world => $world );
    push @{$self->commands}, $command; 


}
