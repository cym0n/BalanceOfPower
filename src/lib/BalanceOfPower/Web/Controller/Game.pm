package BalanceOfPower::Web::Controller::Game;
use Mojo::Base 'Mojolicious::Controller';

use v5.10;
use Data::Dumper;
use MongoDB;
use BalanceOfPower::Relations::Friendship;
use BalanceOfPower::Relations::War;
use BalanceOfPower::Relations::Influence;

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
    $c->render(template => 'bop/supports');
}



1;
