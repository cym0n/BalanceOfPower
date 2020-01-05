package BalanceOfPower::Web;
use Mojo::Base 'Mojolicious';
use Cwd 'abs_path';
use File::Path 'make_path';

use BalanceOfPower::Utils qw( next_turn prev_turn compare_turns add_turns load_nations_data );

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

    my $module_file_path = __FILE__;
    my $root_path = abs_path($module_file_path);
    $root_path =~ s/Web\.pm//;
    my $data_directory = $root_path . "data";
    my %nations_data = load_nations_data("$data_directory/nations-v2.txt");
    my %nation_codes = ();
    for(keys %nations_data)
    {
        $nation_codes{$_} = $nations_data{$_}->{code};
    }
    $c->stash(nation_codes => \%nation_codes);

    my $game = undef;

    my $client = MongoDB->connect();


    if( $c->req->url->path->contains('/api/interaction') )
    {
        $game = $c->param('game');
        if($game)
        {
            say "Looking for $game in bop_games";
            my $db = $client->get_database("bop_games");
            my ($data) = $db->get_collection('games')->find({ name => $game })->all;
            if($data)
            {
                say "Game $game found";
                $c->stash(game => $game);
                $c->stash(first_year => $data->{first_year} . '/1');
                $c->stash(current_year => $data->{current_year});
                my $nation = $c->param('nation');
                if($nation)
                {
                    my $db_date = $data->{current_year};
                    $db_date =~ s/\//_/;
                    my $db_nation_name = "bop_" . $game . "_" . $db_date;
                    my $db_nation = $client->get_database($db_nation_name);
                    say "Looking for $nation in $db_nation_name";
                    my ($nation_data) = $db_nation->get_collection('nations')->find({ code => $nation })->all;
                    if($nation_data)
                    {
                        say "Nation $nation found";
                        $c->stash('nation_code' => $nation_data->{code});
                        $c->stash('nation_name' => $nation_data->{name});
                    }
                }
            }
        }
    }
    elsif($c->req->url->path->contains('/g') || $c->req->url->path->contains('/n'))
    {
        $game = $c->param('game');
        my $year = $c->param('year');
        my $turn = $c->param('turn');
        my $ncode = $c->param('nationcode');
        my $alert = $c->param('alert');

        $c->stash(alert => $alert) if $alert;

        if($game)
        {
            my $db = $client->get_database("bop_games");
            my ($data) = $db->get_collection('games')->find({ name => $game })->all;
            $c->stash(first_year => $data->{first_year} . '/1');
            $c->stash(current_year => $data->{current_year});
            if($year && $turn)
            {
                if(compare_turns("$year/$turn", $data->{current_year}) <= 0 &&
                   compare_turns("$year/$turn", $data->{first_year}) >= 0)
                {
                }
                else
                {
                    return $c->reply->not_found
                }
                my $prev_turn = prev_turn("$year/$turn");
                $c->stash(prev_turn => $prev_turn) if(compare_turns($prev_turn, $data->{first_year}) > 0);
                my $next_turn = next_turn("$year/$turn");
                $c->stash(next_turn => $next_turn) if(compare_turns($next_turn, $data->{current_year}) < 0);
            }
            if($ncode)
            {
                my $dbp = $client->get_database('bop_' . $game . '_interactions');
                my ( $bet ) = $dbp->get_collection('bets')->find({ nation => $ncode })->all;
                if($bet)
                {
                    $bet->{end} = add_turns($bet->{start_year}, $bet->{duration});
                    $c->stash('bet' => $bet);
                }
            }
        }
    } 
    if($game)
    {
        my $dbp = $client->get_database('bop_' . $game . '_interactions');
        my $player = $dbp->get_collection('players')->find()->next();
        $c->stash(player => $player);
    }
    return $next->();
  });

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('game#home');
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
  $r->post('/api/interaction/add-player')->to('interactive#add_player');
  $r->post('/api/interaction/add-bet')->to('interactive#add_bet');
}

1;
