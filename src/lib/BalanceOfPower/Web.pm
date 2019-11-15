package BalanceOfPower::Web;
use Mojo::Base 'Mojolicious';

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

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('example#welcome');
  $r->get('/g/:game/:year/:turn/newspaper')->to('game#newspaper');
  $r->get('/g/:game/:year/:turn/hotspots')->to('game#hotspots');
  $r->get('/g/:game/:year/:turn/alliances')->to('game#alliances');
  $r->get('/g/:game/:year/:turn/influences')->to('game#influences');
  $r->get('/g/:game/:year/:turn/supports')->to('game#supports');
  $r->get('/g/:game/:year/:turn/rsupports')->to('game#rebel_supports');
  $r->get('/g/:game/:year/:turn/warhistory')->to('game#war_history');
  $r->get('/g/:game/:year/:turn/cwarhistory')->to('game#civil_war_history');
  $r->get('/n/:game/:year/:turn/:nationcode/view')->to('game#nation');
  $r->get('/n/:game/:year/:turn/:nationcode/borders')->to('game#borders');
  $r->get('/n/:game/:year/:turn/:nationcode/diplomacy')->to('game#diplomacy');
  $r->get('/n/:game/:year/:turn/:nationcode/events')->to('game#nation_events');
  $r->get('/n/:game/:year/:turn/:nationcode/graphs')->to('game#nation_graphs');
  $r->get('/n/:game/:year/:turn/:nationcode/near')->to('game#near');
}

1;
