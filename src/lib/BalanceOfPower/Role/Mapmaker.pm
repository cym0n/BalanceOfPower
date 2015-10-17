package BalanceOfPower::Role::Mapmaker;

use v5.10;
use strict;
use Moo::Role;

use BalanceOfPower::Relations::Border;
use BalanceOfPower::Relations::RelPack;

has borders => (
    is => 'ro',
    default => sub { BalanceOfPower::Relations::RelPack->new() },
    handles => { add_border => 'add_link',
                 border_exists => 'exists_link',
                 print_borders => 'print_links',
                 get_borders => 'links_for_node',
               }
);

has distance_cache => (
    is => 'rw',
    default => sub { {} }
);

sub load_borders
{
    my $self = shift;
    my $bordersfile = shift;
    my $file = shift || $self->data_directory . "/" . $bordersfile;
    open(my $borders, "<", $file) || die $!;;
    for(<$borders>)
    {
        chomp;
        my $border = $_;
        my @nodes = split(/,/, $border);
        if($self->check_nation_name($nodes[0]) && $self->check_nation_name($nodes[1]))
        {
            if($nodes[0] && $nodes[1] && ! $self->border_exists($nodes[0], $nodes[1]))
            {
                my $b = BalanceOfPower::Relations::Border->new(node1 => $nodes[0], node2 => $nodes[1]);
                $self->add_border($b);
            }
        }
        else
        {
            say "WRONG BORDER: $border";
        }
    }
}

sub near_nations
{
    my $self = shift;
    my $nation = shift;
    my $geographical = shift || 0;
    if($geographical)
    {
        return grep { $self->border_exists($nation, $_) && $nation ne $_ } @{$self->nation_names};
    }
    else
    {
        return grep { $self->in_military_range($nation, $_) && $nation ne $_ } @{$self->nation_names};
    }
}
sub print_near_nations
{
    my $self = shift;
    my $nation = shift;
    my $out = "";
    for($self->near_nations($nation))
    {
        $out .= $_ . "\n";
    }
    return $out;
}


sub get_group_borders
{
    my $self = shift;
    my $group1 = shift;
    my $group2 = shift;
    my @from = @{ $group1 };
    my @to = @{ $group2 };
    my @out = ();
    foreach my $to_n (@to)
    {
        foreach my $from_n (@from)
        {
            if($self->in_military_range($from_n, $to_n))
            {
                push @out, $to_n;
                last;
            }
        }
    }
    return @out;
}

#cache management
sub get_cached_distance
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    if(exists $self->distance_cache->{$nation1} &&
       exists $self->distance_cache->{$nation1}->{$nation2} &&
       $self->distance_cache->{$nation1}->{$nation2} != -1)
    {
        return $self->distance_cache->{$nation1}->{$nation2};
    }
    else
    {
        return undef;
    }
}
sub get_cached_nodes
{
    my $self = shift;
    my $nation1 = shift;
    my %nodes = ();
    if(exists $self->distance_cache->{$nation1})
    {
        %nodes = %{$self->distance_cache->{$nation1}->{nodes}};
    }
    else
    {
        foreach(@{$self->nation_names})
        {
            $nodes{$_}->{distance} = -1;
        }
    }
    return %nodes;
}
#BFS implementation
sub distance
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    my %nodes = $self->get_cached_nodes($nation1);
    if($nodes{$nation2}->{distance} != -1)
    {
        return $nodes{$nation2}->{distance};
    }
    if(my $cached_distance = $self->get_cached_distance($nation2, $nation1))
    {
      $nodes{$nation2}->{distance} = $cached_distance;
      $self->distance_cache->{$nation1}->{nodes} = \%nodes;
      return $cached_distance;
    }

    my @queue = ( $nation1 );
    if(exists $self->distance_cache->{$nation1}->{queue})
    {
        @queue = @{$self->distance_cache->{$nation1}->{queue}};
    }
    while(@queue)
    {
        my $n = shift @queue;
        foreach my $near ($self->near_nations($n, 1))
        {
            if($nodes{$near}->{distance} == -1)
            {
                if($nodes{$n}->{distance} == -1)
                {
                    $nodes{$near}->{distance} = 1;
                }
                else
                {
                    $nodes{$near}->{distance} = $nodes{$n}->{distance} + 1;
                }
                push @queue, $near;
                if($near eq $nation2)
                {
                    $self->distance_cache->{$nation1}->{nodes} = \%nodes;
                    $self->distance_cache->{$nation1}->{queue} = \@queue;
                    return $nodes{$near}->{distance};
                }
            }
        }
    }
    $nodes{$nation2}->{distance} = 100;
    $self->distance_cache->{$nation1}->{nodes} = \%nodes;
    $self->distance_cache->{$nation1}->{queue} = \@queue;
    return 100;
}
sub print_distance
{
    my $self = shift;
    my $n1 = shift;
    my $n2 = shift;
    return "Distance between $n1 and $n2: " . $self->distance($n1, $n2);
}



1;
