package BalanceOfPower::Commands::DeclareWar;

use Moo;

extends 'BalanceOfPower::Commands::Plain';

sub extract_argument
{
    my $self = shift;
    my $query = shift;
    my $extract = shift;
    $extract = 1 if(! defined $extract);
    my $name = $self->name;
    if($query =~ /^$name$/)
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
        if($query =~ /^$syn$/)
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

