package BalanceOfPower::Web::Controller::Game;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub newspaper {
    my $c = shift;
    my $game = $c->param('game');

    # Render template "example/welcome.html.ep" with message
    $c->render(template => 'bop/newspaper');
    #$c->render(msg => "Here will be the newspaper! The game is $game");
}

1;
