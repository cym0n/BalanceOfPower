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
    my $game = c->param('game');
    my $nation = c->param('nation');
    my $lasting = c->param('lasting');
    my $side = c->param('side');
    my $value = c->param('value');

    my $world = BalanceOfPower::World->load_mongo($game); 
    my $nation_obj = $world->get_nation($nation);
    if(! $nation_obj)
    {
        die "$nation is not a nation";
    }
    if(! grep {$_ == $lasting} (2, 4, 8) )
    {
        die "Bad value for lasting: $lasting";
    }
    if(! grep {$_ eq $side} ( 'for', 'against') )
    {
        die "Bad value for side: $side";
    }





}

1;
