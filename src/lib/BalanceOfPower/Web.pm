package BalanceOfPower::Web;
use Mojo::Base 'Mojolicious';
use BalanceOfPower::Utils qw( next_turn prev_turn compare_turns );

# This method will run once at server start
sub startup {
  my $self = shift;

  $self->plugin('TemplateToolkit');
  $self->renderer->default_handler('tt2');
  $self->defaults(layout => 'bop');

  # Load configuration from hash returned by config file
  my $config = $self->plugin('Config');

  # Configure the application
  $self->secrets($config->{secrets});

  $self->hook(around_action => sub {
    my ($next, $c, $action, $last) = @_;
    local $_ = $c;
    my $game = $c->param('game');
    my $year = $c->param('year');
    my $turn = $c->param('turn');

    if($game)
    {
        my $client = MongoDB->connect();
        my $db = $client->get_database("bop_games");
        my ($data) = $db->get_collection('games')->find({ name => $game })->all;
        $c->stash(first_year => $data->{first_year} . '/1');
        $c->stash(current_year => $data->{current_year});
        if($year && $turn)
        {
            if(compare_turns("$year/$turn", $data->{current_year}) <= 0 &&
               compare_turns("$year/$turn", $data->{first_year}) >= 0)
            {
                say $data->{first_year} . " -> " . "$year/$turn" . " -> " . $data->{current_year};
            }
            else
            {
                return $c->reply->not_found
            }
            my $prev_turn = prev_turn("$year/$turn");
            $c->stash(prev_turn => $prev_turn) if(compare_turns($prev_turn, $data->{first_year}) > 0);
            my $next_turn = next_turn("$year/$turn");
            $c->stash(next_turn => $next_turn) if(compare_turns($next_turn, $data->{current_year}) < 0);
            say "$prev_turn (" . compare_turns($prev_turn, $data->{first_year}) . ") < > (" . compare_turns($next_turn, $data->{current_year}) . ") $next_turn";
        }
    }


    return $next->();
  });

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('example#welcome');
  $r->get('/g/:game/years')->to('game#years');
  $r->get('/g/:game/:year/:turn/newspaper')->to('game#newspaper');
  $r->get('/g/:game/:year/:turn/hotspots')->to('game#hotspots');
  $r->get('/g/:game/:year/:turn/alliances')->to('game#alliances');
  $r->get('/g/:game/:year/:turn/influences')->to('game#influences');
  $r->get('/g/:game/:year/:turn/supports')->to('game#supports');
  $r->get('/g/:game/:year/:turn/rsupports')->to('game#rebel_supports');
  $r->get('/g/:game/:year/:turn/warhistory')->to('game#war_history');
  $r->get('/g/:game/:year/:turn/cwarhistory')->to('game#civil_war_history');
  $r->get('/g/:game/:year/:turn/events')->to('game#events');
  $r->get('/g/:game/:year/:turn/statistics')->to('game#statistics');
  $r->get('/n/:game/:year/:turn/:nationcode/view')->to('game#nation');
  $r->get('/n/:game/:year/:turn/:nationcode/borders')->to('game#borders');
  $r->get('/n/:game/:year/:turn/:nationcode/diplomacy')->to('game#diplomacy');
  $r->get('/n/:game/:year/:turn/:nationcode/events')->to('game#events');
  $r->get('/n/:game/:year/:turn/:nationcode/graphs')->to('game#nation_graphs');
  $r->get('/n/:game/:year/:turn/:nationcode/near')->to('game#near');
}

1;
