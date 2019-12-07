package BalanceOfPower::Role::Recorder;

use strict;
use v5.10;

use Moo::Role;
use MongoDB;
use Data::Dumper;
use BalanceOfPower::Nation;
use BalanceOfPower::CivilWar;
use BalanceOfPower::Executive;
use BalanceOfPower::Utils qw(prev_turn next_turn);

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
    $db->get_collection('games')->find_one_and_delete({ name => $self->name});
    $db->get_collection('games')->insert_one($self->to_mongo);
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

sub clean_runtime_mongo
{
    my $self = shift;
    my $mongo = MongoDB->connect(); 
    my $db = $mongo->get_database('bop_' . $self->name . '_runtime')->drop;
}

sub to_mongo_memorial
{
    my $self = shift;
    my $war_type = shift;
    my $war = shift;
    my $mongo = MongoDB->connect();

    my $data = $war->to_mongo();
    $data->{war_type} = $war_type;
    my $db = $mongo->get_database('bop_' . $self->name . '_runtime')->get_collection('memorial')->insert_one($data);
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

sub load_mongo
{
    my $package = shift;
    my $game = shift;
    my $time = shift;
    my ($year, $turn) = split '/', $time;
    my $db_dump_name = join('_', 'bop', $game, $year, $turn);

    my $mongo = MongoDB->connect(); 
    my $db = $mongo->get_database('bop_games');
    my ($world_mongo) = $db->get_collection('games')->find({ name => $game})->all();
    my $world = $package->new( name => $game, mongo_save => 1, first_year => $world_mongo->{first_year}, log_active => 0, mongo_runtime_db => 'bop_' . $game . '_runtime' );

    #nations
    $db = $mongo->get_database($db_dump_name);
    my @nations = $db->get_collection('nations')->find()->all();
    my @nation_names = ();
    foreach my $n (@nations)
    {
        $n->{mongo_runtime_db} = $world->mongo_runtime_db;
        my $executive = BalanceOfPower::Executive->new( actor => $n->{name} );
        $executive->init($world);
        my $n_obj = BalanceOfPower::Nation->from_mongo($n, $world->mongo_runtime_db);
        $n_obj->executive($executive);
        #    log_active => $self->log_active,
        #    log_dir => $self->log_dir,
        #    log_name => $self->log_name,
        #    log_on_stdout => $self->log_on_stdout,
        #    mongo_save => $self->mongo_save,
        #    mongo_events_collection => $self->name
        push @{$world->nations}, $n_obj;
        push @nation_names, $n->{name};
        $world->nation_codes->{$n->{code}} = $n->{name};
    }
    $world->nation_names(\@nation_names);

    my @borders = $db->get_collection('relations')->find({ rel_type => 'border'})->all();
    foreach my $b (@borders)
    {
        $world->add_border(BalanceOfPower::Relations::Border->from_mongo($b));
    }
    my @diplomacy = $db->get_collection('relations')->find({ rel_type => 'friendship'})->all();
    foreach my $f (@diplomacy)
    {
        $world->add_diplomacy(BalanceOfPower::Relations::Friendship->from_mongo($f));
    }
    my @supports = $db->get_collection('relations')->find({ rel_type => 'support'})->all();
    foreach my $s (@supports)
    {
        $world->add_military_support(BalanceOfPower::Relations::MilitarySupport->from_mongo($s));
    }
    my @rsupports = $db->get_collection('relations')->find({ rel_type => 'rebel_support'})->all();
    foreach my $rs (@rsupports)
    {
        $world->add_rebel_military_support(BalanceOfPower::Relations::MilitarySupport->from_mongo($rs));
    }
    my @wars = $db->get_collection('relations')->find({ rel_type => 'war'})->all();
    foreach my $w (@wars)
    {
        $world->add_war(BalanceOfPower::Relations::War->from_mongo($w, $world->mongo_runtime_db));
    }
    my @influences = $db->get_collection('relations')->find({ rel_type => 'influence'})->all();
    foreach my $i (@influences)
    {
        $world->add_influence(BalanceOfPower::Relations::Influence->from_mongo($i));
    }
    my @routes = $db->get_collection('relations')->find({ rel_type => 'traderoute'})->all();
    foreach my $tr (@routes)
    {
        $world->add_traderoute(BalanceOfPower::Relations::TradeRoute->from_mongo($tr));
    }
    my @treaties = $db->get_collection('relations')->find({ rel_type => 'treaty'})->all();
    foreach my $t (@treaties)
    {
        $world->add_treaty(BalanceOfPower::Relations::Treaty->from_mongo($t));
    }
    my @civil_wars = $db->get_collection('civil_wars')->find()->all();
    foreach my $cw (@civil_wars)
    {
        my $cw_obj = BalanceOfPower::CivilWar->from_mongo($cw, $world->mongo_runtime_db);
        $cw_obj->load_nation($world);
        $world->_add_civil_war($cw_obj);
    }
    my ($statistics) = $db->get_collection('statistics')->find()->all();
    $world->statistics_from_mongo($time, $statistics);
    my $runtime_db = $mongo->get_database('bop_' . $game . '_runtime');
    my @events = $runtime_db->get_collection('events')->find({ time => $time})->all();
    foreach my $e (@events)
    {
        if($e->{source_type} eq 'world')
        {
            $world->event_from_mongo($e);
        }
        elsif($e->{source_type} eq 'nation')
        {
            my $n = $world->get_nation($e->{source});
            $n->event_from_mongo($e);
        }
        elsif($e->{source_type} eq 'war')
        {
            my $w = $world->war_from_id($e->{source});
            if($w)
            {
                $w->event_from_mongo($e);
            }
            else
            {
                #War already sent to memorial
            }
        }
        elsif($e->{source_type} eq 'civil_war')
        {
            if($e->{source} =~ /^(.*) (\d+)\/\d$/)
            {
                my $cw = $world->get_civil_war($1);
                $cw->event_from_mongo($e);
            }
            else
            {
                die "Bad civil war name: " . $e->{source};
            }
        }
        
    }
    $world->events->{$time} = \@events;


    return $world;
}

1;
