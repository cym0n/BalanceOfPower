package BalanceOfPower::Web::Controller::Game;
use Mojo::Base 'Mojolicious::Controller';

use v5.10;
use Data::Dumper;
use MongoDB;
use BalanceOfPower::World;
use BalanceOfPower::Relations::Friendship;
use BalanceOfPower::Relations::War;
use BalanceOfPower::Relations::Influence;
use BalanceOfPower::Relations::Treaty;
use BalanceOfPower::Relations::TradeRoute;
use BalanceOfPower::Relations::MilitarySupport;
use BalanceOfPower::Nation;
use BalanceOfPower::Utils qw( next_turn prev_turn );

my $nation_codes = {
'Nicaragua' => 'NIC',
'Romania' => 'ROM',
'Kenya' => 'KEN',
'Iran' => 'IRI',
'East Germany' => 'DDR',
'South Korea' => 'KOR',
'China' => 'CHN',
'Australia' => 'AUS',
'Canada' => 'CAN',
'Tanzania' => 'TAN',
'Syria' => 'SYR',
'Zimbabwe' => 'ZIM',
'West Germany' => 'BRD',
'Burma' => 'BIR',
'Japan' => 'JAP',
'North Korea' => 'PRK',
'Thailand' => 'THA',
'USA' => 'USA',
'Egypt' => 'EGY',
'United Kingdom' => 'GBR',
'Algeria' => 'ALG',
'Poland' => 'POL',
'Morocco' => 'MOR',
'Turkey' => 'TUR',
'USSR' => 'URS',
'Mali' => 'MAL',
'Brazil' => 'BRA',
'Argentina' => 'ARG',
'Cuba' => 'CUB',
'Greece' => 'GRE',
'Philippines' => 'PHI',
'Mexico' => 'MEX',
'Colombia' => 'COL',
'Ethiopia' => 'ETH',
'Libya' => 'LIB',
'Sweden' => 'SWE',
'Chile' => 'CHI',
'Peru' => 'PER',
'Tunisia' => 'TUN',
'Spain' => 'SPA',
'Israel' => 'ISR',
'Venezuela' => 'VEN',
'Honduras' => 'HON',
'France' => 'FRA',
'Indonesia' => 'INA',
'Angola' => 'ANG',
'Czechoslovakia' => 'CZE',
'Taiwan' => 'TWN',
'Zaire' => 'ZAI',
'Afghanistan' => 'AFG',
'Italy' => 'ITA',
'Iraq' => 'IRQ',
'Saudi Arabia' => 'KSA',
'Pakistan' => 'PAK',
'Panama' => 'PAN',
'Sudan' => 'SUD',
'Mozambique' => 'MOZ',
'India' => 'IND',
'Yugoslavia' => 'YUG',
'Nigeria' => 'NIG',
'Vietnam' => 'VIE',
'South Africa' => 'RSA'
};

# This action will render a template
sub newspaper {
    my $c = shift;
    my $game = $c->param('game');
    my $year = $c->param('year');
    my $turn = $c->param('turn');
    my $db_dump_name = join('_', 'bop', $game, $year, $turn);
    #db.mongo.find({$and: [ {code: 'bestprogress'}, {time: '1970/2'}, {source_type: 'world'} ]}).pretty()
    my $client = MongoDB->connect();
    my $db = $client->get_database('bop_events');
     

    $c->stash(title => "NEWS FOR $year/$turn");

    foreach my $event ( qw(bestprogress bestwealth civiloutbreak govwincivil rebwincivil tradeadded tradedeleted comtreatynew nagtreatynew alliancetreatynew nagtreatybroken alltreatybroken comtreatybroken militaryaid economicaid insurgentsaid supstarted supincreased supstopped suprefused supdestroyed rebsupincreased rebsupstopped rebsupstarted))
    {
        my @data = ();
        my $cursor = $db->get_collection($game)->find({ code => $event, 'time' => "$year/$turn", "source_type" => 'world'});
        while(my $obj = $cursor->next) {
            push @data, $obj;
        }
        $c->stash($event => \@data);
    }

    my @warevents = ( $db->get_collection($game)->find({ code => 'warstart', 'time' => "$year/$turn", "source_type" => 'world'})->all);
    @warevents = (@warevents, $db->get_collection($game)->find({ code => 'warlinkedstart', 'time' => "$year/$turn", "source_type" => 'world'})->all);
    @warevents = (@warevents, $db->get_collection($game)->find({ code => 'warend', 'time' => "$year/$turn", "source_type" => 'world'})->all);
    my %wars;
    foreach my $e (@warevents)
    {
        my $war_id = $e->{values}->[0];
        my $key = $e->{code};
        if($key eq 'warstart')
        {
            $wars{$war_id}->{'warstart'} = $e;
        }
        elsif($key eq 'warlinkedstart')
        {
            if(exists $wars{$war_id} && exists $wars{$war_id}->{'warlinkedstart'})
            {
                push @{ $wars{$war_id}->{'warlinkedstart'} }, $e;
            }
            else
            {
                $wars{$war_id}->{'warlinkedstart'} = [ $e ];
            }
        }
        elsif($key eq 'warend')
        {
            if(exists $wars{$war_id} && exists $wars{$war_id}->{'warend'})
            {
                push @{ $wars{$war_id}->{'warend'} }, $e;
            }
            else
            {
                $wars{$war_id}->{'warend'} = [ $e ];
            }
        }
    }
    $c->stash( wars => \%wars );

    $c->stash(nation_codes => $nation_codes);

    $c->render(template => 'bop/newspaper');
}
sub hotspots {
    my $c = shift;
    my $game = $c->param('game');
    my $year = $c->param('year');
    my $turn = $c->param('turn');
    my $db_dump_name = join('_', 'bop', $game, $year, $turn);
    #db.mongo.find({$and: [ {code: 'bestprogress'}, {time: '1970/2'}, {source_type: 'world'} ]}).pretty()
    my $client = MongoDB->connect();
    my $db = $client->get_database($db_dump_name);
    my $cursor;
    $cursor = $db->get_collection('relations')->find({ rel_type => 'friendship', crisis_level => {'$gt' => 0}});
    my @crises = ();
    while(my $obj = $cursor->next) {
        my $c = BalanceOfPower::Relations::Friendship->from_mongo($obj);
        push @crises, $c;
    }
    $c->stash(crises => \@crises);

    $cursor = $db->get_collection('relations')->find({ rel_type => 'war'});
    my @war_rel = ();
    while(my $obj = $cursor->next) {
        my $w = BalanceOfPower::Relations::War->from_mongo($obj);
        push @war_rel, $w;
    }

    my %grouped_wars;
    foreach my $w (@war_rel)
    {
        if(! exists $grouped_wars{$w->war_id})
        {
            $grouped_wars{$w->war_id} = [];
        }
        push @{$grouped_wars{$w->war_id}}, $w; 
    }
    my @wars;
    foreach my $k (keys %grouped_wars)
    {
        my %war;
        $war{'name'} = $k;
        $war{'conflicts'} = [];
        foreach my $w ( @{$grouped_wars{$k}})
        {
            my %subwar;
            $subwar{'node1'} = $w->node1;
            $subwar{'node2'} = $w->node2;

            my $nation1 = $db->get_collection('nations')->find({ name => $w->node1})->next;
            my $nation2 = $db->get_collection('nations')->find({ name => $w->node2})->next;

            $subwar{'army1'} = $nation1->{army};
            $subwar{'army2'} = $nation2->{army};
            $subwar{'node1_faction'} = $w->node1_faction;
            $subwar{'node2_faction'} = $w->node2_faction;
            push @{$war{'conflicts'}}, \%subwar;
        }
        push @wars, \%war;
    }
    $c->stash(wars => \@wars);

    $cursor = $db->get_collection('civil_wars')->find();
    my @civil_wars = ();
    while(my $obj = $cursor->next) {
        push @civil_wars, $obj->{nation_name};
    }
    $c->stash(civil_wars => \@civil_wars);


    $c->stash(nation_codes => $nation_codes);

    $c->render(template => 'bop/hotspots');
}

sub alliances
{
    my $c = shift;
    my $game = $c->param('game');
    my $year = $c->param('year');
    my $turn = $c->param('turn');
    my $db_dump_name = join('_', 'bop', $game, $year, $turn);
    #db.relations.find({$and: [{ rel_type: 'treaty'}, {type: 'alliance'}]}).pretty()
    my $client = MongoDB->connect();
    my $db = $client->get_database($db_dump_name);
    my $cursor;
    my @alls = $db->get_collection('relations')->find({ rel_type => 'treaty', type => 'alliance'})->all;
    $c->stash(treaties => \@alls);
    $c->stash(nation_codes => $nation_codes);
    $c->render(template => 'bop/alliances');
}


sub influences
{
    my $c = shift;
    my $game = $c->param('game');
    my $year = $c->param('year');
    my $turn = $c->param('turn');
    my $db_dump_name = join('_', 'bop', $game, $year, $turn);
    #db.relations.find({$and: [{ rel_type: 'treaty'}, {type: 'alliance'}]}).pretty()
    my $client = MongoDB->connect();
    my $db = $client->get_database($db_dump_name);
    my $cursor = $db->get_collection('relations')->find({ rel_type => 'influence'});
    my @inf;
    while(my $obj = $cursor->next) {
        push @inf, BalanceOfPower::Relations::Influence->from_mongo($obj);
    }
    @inf = sort { lc($a->node1) cmp lc($b->node1) } @inf;
    $c->stash(influences => \@inf);
    $c->stash(nation_codes => $nation_codes);
    $c->render(template => 'bop/influences');
}



sub supports
{
    my $c = shift;
    my $game = $c->param('game');
    my $year = $c->param('year');
    my $turn = $c->param('turn');
    my $db_dump_name = join('_', 'bop', $game, $year, $turn);
    #db.relations.find({$and: [{ rel_type: 'treaty'}, {type: 'alliance'}]}).pretty()
    my $client = MongoDB->connect();
    my $db = $client->get_database($db_dump_name);
    my $cursor;
    my @sups = $db->get_collection('relations')->find({ rel_type => 'support'})->all;
    $c->stash(title => "MILITARY SUPPORTS");
    $c->stash(supports => \@sups);
    $c->stash(nation_codes => $nation_codes);
    $c->render(template => 'bop/supports');
}

sub rebel_supports
{
    my $c = shift;
    my $game = $c->param('game');
    my $year = $c->param('year');
    my $turn = $c->param('turn');
    my $db_dump_name = join('_', 'bop', $game, $year, $turn);
    #db.relations.find({$and: [{ rel_type: 'treaty'}, {type: 'alliance'}]}).pretty()
    my $client = MongoDB->connect();
    my $db = $client->get_database($db_dump_name);
    my $cursor;
    my @sups = $db->get_collection('relations')->find({ rel_type => 'rebel_support'})->all;
    $c->stash(title => "REBEL SUPPORTS");
    $c->stash(supports => \@sups);
    $c->stash(nation_codes => $nation_codes);
    $c->render(template => 'bop/supports');
}

sub nation
{
    my $c = shift;
    my $game = $c->param('game');
    my $year = $c->param('year');
    my $turn = $c->param('turn');
    my $n_code = $c->param('nationcode');
    my $db_dump_name = join('_', 'bop', $game, $year, $turn);
    my $attributes_names = ["Size", "Prod.", "Wealth", "W/D", "Growth", "Disor.", "Army", "Prog.", "Pstg."];
    my $attributes = ["production", "wealth", "w/d", "growth", "internal disorder", "army", "progress", "prestige"];
    my $client = MongoDB->connect();
    my $db = $client->get_database($db_dump_name);
    my $world = BalanceOfPower::World->load_mongo($game, "$year/$turn"); 
    my $nation = $world->nation_codes->{uc $n_code};

    my $nation_obj = $world->get_nation($nation);
    my $under_influence = $world->is_under_influence($nation);
    my @influence = $world->has_influence($nation);
    my @routes = $world->routes_for_node($nation);
    my @treaties = $world->get_treaties_for_nation($nation);
    my @supports = $world->supports($nation);
    my @rebel_supports = $world->rebel_supports($nation);
    my @crises = $world->get_crises($nation);
    my @wars = $world->get_wars($nation);
    $c->stash(nation => $nation_obj);
    $c->stash(traderoutes => \@routes);
    $c->stash(treaties => \@treaties);
    $c->stash(supports => \@supports);
    $c->stash(rebel_supports => \@rebel_supports);
    $c->stash(crises => \@crises);
    $c->stash(wars => \@wars);
    my ($stats) = $db->get_collection('statistics')->find()->all;
    my @ndata = ($nation_obj->size);
    for(@{$attributes})
    {
        push @ndata, $stats->{$nation_obj->name}->{$_};
    }

    $c->stash(nationstats => \@ndata);
    $c->stash(influence => \@influence);
    $c->stash(under_influence => $under_influence);
    if(@treaties > @supports + @rebel_supports)
    {
        $c->stash(first_row_height => scalar @treaties);
    }
    else
    {
        $c->stash(first_row_height => scalar ( @supports + @rebel_supports));
    }
    my $second_row_height;
    if(@crises > @wars)
    {
        $c->stash(second_row_height => scalar @crises);
    }
    else
    {
        $c->stash(second_row_height => scalar @wars);
    }
    $c->stash(latest_order => $stats->{$nation_obj->name}->{'order'});
    $c->stash(nation_codes => $nation_codes);
    $c->stash(nation_menu => 1);
    $c->stash(attributes => $attributes_names);





    $c->render(template => 'bop/nation');
}
sub borders
{
    my $c = shift;
    my $game = $c->param('game');
    my $year = $c->param('year');
    my $turn = $c->param('turn');
    my $n_code = $c->param('nationcode');

    
    my $world = BalanceOfPower::World->load_mongo($game, "$year/$turn"); 
    my $nation = $world->nation_codes->{uc $n_code};
    my @borders = $world->near_nations($nation, 1);
    my %data;

    foreach my $b (@borders)
    {
        my $rel = $world->diplomacy_exists($nation, $b);
        $data{$b}->{'relation'} = $rel;

        my $supps = $world->supported($b);
        if($supps)
        {
            my $supporter = $supps->start($b);
            $data{$b}->{'support'}->{nation} = $supporter;
            my $sup_rel = $world->diplomacy_exists($nation, $supporter);
            $data{$b}->{'support'}->{relation} = $sup_rel;
        }
    }
    $c->stash( nation => $world->get_nation($nation) );
    $c->stash( borders => \%data );
    $c->stash( nation => $world->get_nation($nation) );
    $c->stash(nation_codes => $nation_codes);
    $c->stash(nation_menu => 1);
    $c->render(template => 'bop/nation/borders');
}

sub diplomacy
{
    my $c = shift;
    my $game = $c->param('game');
    my $year = $c->param('year');
    my $turn = $c->param('turn');
    my $n_code = $c->param('nationcode');
    my $db_dump_name = join('_', 'bop', $game, $year, $turn);
    my $client = MongoDB->connect();
    my $db = $client->get_database($db_dump_name);
    my $nation_mongo = $db->get_collection('nations')->find({ code => $n_code})->next;
    my $nation =  BalanceOfPower::Nation->from_mongo($nation_mongo);
    my $cursor = $db->get_collection('relations')->find({ '$or' => [{ node1 => $nation->name}, {node2=> $nation->name}], '$and' => [{ rel_type => 'friendship' }]});
    my @friendships = ();
    while(my $obj = $cursor->next) {
        push @friendships, BalanceOfPower::Relations::Friendship->from_mongo($obj);
    }
    $c->stash( nation => $nation );
    $c->stash( relationships => \@friendships );
    $c->stash(nation_codes => $nation_codes);
    $c->stash(nation_menu => 1);
    $c->render(template => 'bop/nation/diplomacy');
}

sub nation_events
{
    my $c = shift;
    my $game = $c->param('game');
    my $year = $c->param('year');
    my $turn = $c->param('turn');
    my $n_code = $c->param('nationcode');
    my $client = MongoDB->connect();
    my $db_dump_name = join('_', 'bop', $game, $year, $turn);
    my $db = $client->get_database($db_dump_name);
    my $nation_mongo = $db->get_collection('nations')->find({ code => $n_code})->next;
    my $nation =  BalanceOfPower::Nation->from_mongo($nation_mongo);
       $db = $client->get_database('bop_events');


    my %events = ();
    my @turns = ();
    my $when = "$year/$turn";
    for(my $i = 0; $i < 4; $i++)
    {
        push @turns, $when;
        my @es = $db->get_collection($game)->find({ time => "$when", source => $nation->name})->all; 
        for(@es)
        {
            push @{$events{$when}}, $_->{text};
        }
        $when = prev_turn($when);
    }



    my @events = $db->get_collection($game)->find({ time => "$year/$turn", source => $nation->name})->all; 
    $c->stash( nation => $nation );
    $c->stash( events => \%events );
    $c->stash( turns => \@turns );
    $c->stash(nation_codes => $nation_codes);
    $c->stash(nation_menu => 1);
    $c->render(template => 'bop/nation/events');
}

sub nation_graphs
{
    my $c = shift;

    my $game = $c->param('game');
    my $year = $c->param('year');
    my $turn = $c->param('turn');
    my $n_code = $c->param('nationcode');
    my @entities = ( "production", "w/d", "internal disorder", "army" );
    my $data;
    my $client = MongoDB->connect();
    my $db_dump_name = join('_', 'bop', $game, $year, $turn);
    my $db = $client->get_database($db_dump_name);
    my $nation_mongo = $db->get_collection('nations')->find({ code => $n_code})->next;
    my $nation =  BalanceOfPower::Nation->from_mongo($nation_mongo);
    my $depth = 10;
    my $when = "$year/$turn";
    for(my $step = 0; $step < $depth; $step++)
    {
        my ($y, $t) = split "/", $when;
        my $db_dump_name = join('_', 'bop', $game, $y, $t);
        my $db = $client->get_database($db_dump_name);
        my ($stats) = $db->get_collection('statistics')->find()->all;
        if($stats)
        {
            foreach my $e ( @entities )
            {
                my $value = $stats->{$nation->name}->{$e};
                $data->{$e} = $data->{$e} ? ", ['$when', $value]" . $data->{$e} : ", ['$when', $value]";
                if(! $data->{min}->{$e} || $value < $data->{min}->{$e})
                {
                    $data->{min}->{$e} = $value;
                }
            }
        }
        $when = prev_turn($when);
    }
    foreach my $e ( @entities )
    {
        $data->{$e} =  "['Turn', '$e']" . $data->{$e};
        say $data->{$e};
    }
    $c->stash(colors => { 'w/d' => '#00c87c',
                        'production' => '#0081c9',
                        'internal disorder' => '#d90d11',
                        'army' => '#736f6e' });
    $c->stash(entities => \@entities);
    $c->stash(object => $nation->name);
    $c->stash(nation => $nation);
    $c->stash(gdata => $data);
    $c->stash(army => $data->{army});
    $c->stash(nation_menu => 1);
    $c->render(template => 'bop/nation/graphs');
}



1;
