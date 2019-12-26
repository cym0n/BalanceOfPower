package BalanceOfPower::Web::Controller::Interactive;
use Mojo::Base 'Mojolicious::Controller';

use v5.10;
use Data::Dumper;
use MongoDB;
use BalanceOfPower::Constants ':all';
use BalanceOfPower::World;

sub add_player
{
    my $c = shift;
    my $game = $c->param('game');
    my $player = $c->param('player');
    my $start_year = $c->param('start_year');
    my $mongo = MongoDB->connect(); 
    my $db = $mongo->get_database('bop_' . $game . '_interactions');
    my @already = $db->get_collection('players')->find()->all();
    if(@already)
    {
        $c->redirect_to('/?alert=player_already');
    }
    else
    {
        $db->get_collection('players')->insert_one({
                                                    name => $player,
                                                    start_year => $start_year,
                                                    funds => STARTING_FUNDS,
                                                    });
        $c->redirect_to('/?alert=player_ok');
    }
}

sub add_bet
{
    my $c = shift;
    my $game = $c->stash('game');
    my $nation = $c->stash('nation_code');
    my $current_year = $c->stash('current_year');
    my $lasting = $c->param('lasting');
    my $side = $c->param('side');
    my $value = $c->param('value');
    my $player = $c->stash('player');

    if(! $game)
    {
        die "Bad game";
    }
    if(! $nation)
    {
        die "Bad nation";
    }
    
    if(! grep {$_ == $lasting} (2, 4, 8) )
    {
        die "Bad value for lasting: $lasting";
    }
    if(! grep {$_ eq $side} ( 'for', 'against') )
    {
        die "Bad value for side: $side";
    }
    my $client = MongoDB->connect(); 
    my $db = $client->get_database('bop_' . $game . '_interactions');
    my ($bet) = $db->get_collection('bets')->find({ game => $game, nation => $nation })->all;

    if($bet)
    {
        $c->redirect_to('/n/' . $game . '/' . $current_year . '/' . $nation . '/view?alert=bet_already');
    }
    else
    {
        if($player->{funds} < $value)
        {
            $c->redirect_to('/n/' . $game . '/' . $current_year . '/' . $nation . '/view?alert=no_funds');
        }
        else
        {
            $db->get_collection('bets')->insert_one({
                                                    game => $game,
                                                    player => $c->stash('player'),
                                                    start_year => $current_year,
                                                    value => $value,
                                                    duration => $lasting,
                                                    side => $side,
                                                    nation => $nation
                                                });
            my $new_funds = $player->{funds} - $value;
            $db->get_collection('players')->update_one({ name => $player->{name}}, { '$set' => { funds => $new_funds }});
            $c->redirect_to('/n/' . $game . '/' . $current_year . '/' . $nation . '/view?alert=bet_ok');
        }
    }
}

1;
