package BalanceOfPower::Role::Recorder;

use strict;
use v5.10;

use Moo::Role;
use MongoDB;
use BalanceOfPower::Nation;
use BalanceOfPower::Executive;

requires 'dump_events';
requires 'load_events';
requires 'diplomacy_for_node';

has mongo_save => (
    is => 'ro',
    default => 0
);

my $dump_version = 3;


sub dump
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
    print {$io} $indent . join(";", $self->name, $self->first_year, $self->current_year, $self->admin_password) . "\n";
    $self->dump_events($io, " " . $indent);
}
sub to_mongo
{
    my $self = shift;
    return {
        name => $self->name,
        first_year => $self->first_year,
        current_year => $self->current_year,
        admin_password => $self->admin_password
    }
}
sub load
{
    my $self = shift;
    my $data = shift;
    my $world_line = ( split /\n/, $data )[0];
    $world_line =~ s/^\s+//;
    chomp $world_line;
    my ($name, $first_year, $current_year, $admin_password) =
        split ";", $world_line;
    $data =~ s/^.*?\n//;
    my $events = $self->load_events($data);
    return BalanceOfPower::World->new(name => $name, 
                                      first_year => $first_year, current_year => $current_year, admin_password => $admin_password,
                                      events => $events);
                                     
}

sub load_nations
{
    my $self = shift;
    my $data = shift;
    my $version = shift;
    $data .= "EOF\n";
    my $nation_data = "";
    foreach my $l (split "\n", $data)
    {

        if($l !~ /^\s/)
        {
            if($nation_data)
            {
                my $nation = BalanceOfPower::Nation->load($nation_data, $version);
                my $executive = BalanceOfPower::Executive->new( actor => $nation->name );
                $executive->init($self);
                $nation->executive($executive);
                push @{$self->nations}, $nation;
                push @{$self->nation_names}, $nation->name;
                $self->nation_codes->{$nation->code} = $nation->name;
            }
            $nation_data = $l . "\n";
        }
        else
        {
            $nation_data .= $l . "\n";
        }
    }
}
sub load_players
{
    my $self = shift;
    my $data = shift;
    my $version = shift;
    $data .= "EOF\n";
    my $player_data = "";
    foreach my $l (split "\n", $data)
    {

        if($l !~ /^\s/ && $l !~ /^$/)
        {
            if($player_data)
            {
                my $player = BalanceOfPower::Player->load($player_data, $version, $self);
                push @{$self->players}, $player;
            }
            $player_data = $l . "\n";
        }
        else
        {
            $player_data .= $l . "\n";
        }
    }
}

sub load_civil_wars
{
    my $self = shift;
    my $data = shift;
    $data .= "EOF\n";
    my $cw_data = "";
    foreach my $l (split "\n", $data)
    {

        if($l !~ /^\s/ && $l !~ /^$/)
        {
            if($cw_data)
            {
                my $cw = BalanceOfPower::CivilWar->load($cw_data);
                $cw->load_nation($self);
                push @{$self->civil_wars}, $cw;
            }
            $cw_data = $l . "\n";
        }
        else
        {
            $cw_data .= $l . "\n";
        }
    }
}



sub dump_all
{
    my $self = shift;
    my $file = shift || $self->savefile;
    return "No file provided" if ! $file;
    open(my $io, "> $file");
    print {$io} "####### V$dump_version\n";
    $self->dump($io);
    print {$io} "### NATIONS\n";
    for(@{$self->nations})
    {
        $_->dump($io);
    }
    print {$io} "### PLAYERS\n";
    for(@{$self->players})
    {
        $_->dump($io);
    }
    print {$io} "### DIPLOMATIC RELATIONS\n";
    $self->diplomatic_relations->dump($io);
    print {$io} "### TREATIES\n";
    $self->treaties->dump($io);
    print {$io} "### BORDERS\n";
    $self->borders->dump($io);
    print {$io} "### TRADEROUTES\n";
    $self->trade_routes->dump($io);
    print {$io} "### INFLUENCES\n";
    $self->influences->dump($io);
    print {$io} "### SUPPORTS\n";
    $self->military_supports->dump($io);
    print {$io} "### REBEL SUPPORTS\n";
    $self->rebel_military_supports->dump($io);
    print {$io} "### WARS\n";
    $self->wars->dump($io);
    print {$io} "### CIVIL WARS\n";
    for(@{$self->civil_wars})
    {
        $_->dump($io);
    }
    print {$io} "### MEMORIAL\n";
    $self->dump_memorial($io);
    print {$io} "### CIVIL MEMORIAL\n";
    $self->dump_civil_memorial($io);
    print {$io} "### STATISTICS\n";
    $self->dump_statistics($io);
    print {$io} "### EOF\n";
    close($io);
    return "World saved to $file";
}   

sub world_to_mongo
{
    my $self = shift;
    my $mongo = MongoDB->connect(); 
    my $db = $mongo->get_database('bop_games');
    $db->get_collection('games')->insert_one_or_replace({ name => $self->name}, $self->to_mongo);
}


sub dump_mongo
{
    my $self = shift;

    $self->world_to_mongo();

    my $db_name = 'bop_' . $self->name . '_'. $self->current_year;
    $db_name =~ s/\//_/;
    my $mongo = MongoDB->connect(); 
    my $db = $mongo->get_database($db_name);
    $db->drop;
    for(@{$self->nations})
    {
        my $n = $_;
        my $doc = $n->to_mongo();
        $db->get_collection('nations')->insert_one($doc);
    }
    for($self->diplomatic_relations->to_mongo)
    {
        $db->get_collection('relations')->insert_one($_);
    }
    for($self->treaties->to_mongo)
    {
        $db->get_collection('relations')->insert_one($_);
    }
    for($self->borders->to_mongo)
    {
        $db->get_collection('relations')->insert_one($_);
    }
    for($self->trade_routes->to_mongo)
    {
        $db->get_collection('relations')->insert_one($_);
    }
    for($self->influences->to_mongo)
    {
        $db->get_collection('relations')->insert_one($_);
    }
    for($self->military_supports->to_mongo)
    {
        $db->get_collection('relations')->insert_one($_);
    }
    for($self->rebel_military_supports->to_mongo)
    {
        $db->get_collection('relations')->insert_one($_);
    }
    for($self->wars->to_mongo)
    {
        $db->get_collection('relations')->insert_one($_);
    }
    for(@{$self->civil_wars})
    {
        $db->get_collection('civil_wars')->insert_one($_->to_mongo());
    }
    $db->get_collection('statistics')->insert_one($self->statistics_to_mongo($self->current_year)); 
    return "World saved to $db_name mongodb";
}

sub clean_mongo_events
{
    my $self = shift;
    my $mongo = MongoDB->connect(); 
    my $db = $mongo->get_database('bop_events')->get_collection($self->name)->drop;
}

sub to_mongo_memorial
{
    my $self = shift;
    my $war_type = shift;
    my $war = shift;
    my $mongo = MongoDB->connect();

    my $data = $war->to_mongo();
    $data->{war_type} = $war_type;
    my $db = $mongo->get_database('bop_memorials')->get_collection($self->name)->insert_one($data);
}

sub clean_mongo_memorial
{
    my $self = shift;
    my $mongo = MongoDB->connect(); 
    my $db = $mongo->get_database('bop_memorials')->get_collection($self->name)->drop;
}





sub load_world
{
    my $self = shift;
    my $file = shift;
    open(my $dump, "<", $file) or die "Problems opening $file: $!";
    my $world;
    my $target = "WORLD";
    my $data = "";
    my $version = undef;
    for(<$dump>)
    {
        my $line = $_;
        if(! $version)
        {
            if($line =~ /^####### V(.*)$/)
            {
                $version = $1;
                if($version != $dump_version)
                {
                    say "WARNING: Dump of version $version";
                }
                next;
            }
            else
            {
                $version = 1;
                if($version != $dump_version)
                {
                    say "WARNING: Dump of version $version";
                }
            }
        }
        if($line =~ /^### (.*)$/)
        {
            my $next = $1;
            if($target eq 'WORLD')
            {
                $world = $self->load($data);
                $world->savefile($file);
            }
            elsif($target eq 'NATIONS')
            {
                $world->load_nations($data, $version);
            }
            elsif($target eq 'PLAYERS')
            {
                $world->load_players($data, $version);
            }
            elsif($target eq 'DIPLOMATIC RELATIONS')
            {
                $world->diplomatic_relations->load_pack("BalanceOfPower::Relations::Friendship", $data);
            }
            elsif($target eq 'TREATIES')
            {
                $world->treaties->load_pack("BalanceOfPower::Relations::Treaty", $data);
            }
            elsif($target eq 'BORDERS')
            {
                $world->borders->load_pack("BalanceOfPower::Relations::Border", $data);
            }
            elsif($target eq 'TRADEROUTES')
            {
                $world->trade_routes->load_pack("BalanceOfPower::Relations::TradeRoute", $data);
            }
            elsif($target eq 'INFLUENCES')
            {
                $world->influences->load_pack("BalanceOfPower::Relations::Influence", $data);
            }
            elsif($target eq 'SUPPORTS')
            {
                $world->military_supports->load_pack("BalanceOfPower::Relations::MilitarySupport", $data);
            }
            elsif($target eq 'REBEL SUPPORTS')
            {
                $world->rebel_military_supports->load_pack("BalanceOfPower::Relations::MilitarySupport", $data);
            }
            elsif($target eq 'WARS')
            {
                $world->wars->load_pack("BalanceOfPower::Relations::War", $data);
                for($world->wars->all())
                {
                    $_->log_active(0);
                }
            }
            elsif($target eq 'CIVIL WARS')
            {
                $world->load_civil_wars($data);
            }
            elsif($target eq 'MEMORIAL')
            {
                $world->memorial($world->load_memorial($data));
            }
            elsif($target eq 'CIVIL MEMORIAL')
            {
                $world->civil_memorial($world->load_civil_memorial($data));
            }
            elsif($target eq 'STATISTICS')
            {
                $world->load_statistics($data);
            }
            $data = "";
            $target = $next;
        }
        else
        {
            $data .= $line;
        }
    }
    close($dump);
    return $world;
}

1;
