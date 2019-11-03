package BalanceOfPower::Web::Controller::Game;
use Mojo::Base 'Mojolicious::Controller';

use v5.10;
use Data::Dumper;
use MongoDB;

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

1;
