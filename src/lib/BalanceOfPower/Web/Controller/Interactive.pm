package BalanceOfPower::Web::Controller::Interactive;
use Mojo::Base 'Mojolicious::Controller';

use v5.10;
use Data::Dumper;
use MongoDB;
use BalanceOfPower::Constants ':all';

sub add_player
{
    my $c = shift;
    my $game = $c->param('game');
    my $player = $c->param('player');
    my $start_year = $c->param('start_year');
    my $mongo = MongoDB->connect(); 
    my $db = $mongo->get_database('bop_' . $game . '_interactions');
    $db->get_collection('players')->insert_one({
                                                    name => $player,
                                                    start_year => $start_year,
                                                    funds => STARTING_FUNDS,
                                               });
    $c->redirect_to('/');
}

1;
