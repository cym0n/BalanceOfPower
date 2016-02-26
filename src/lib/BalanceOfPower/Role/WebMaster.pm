package BalanceOfPower::Role::WebMaster;

use strict;
use v5.10;
use Moo::Role;

use LWP::UserAgent;
use JSON;
use Data::Dumper;
use File::Path 'make_path';

use BalanceOfPower::Utils qw(prev_turn next_turn);


has site_root => (
    is => 'rw',
);
has api_url => (
    is => 'rw',
);

requires 'print_hotspots';
requires 'print_allies';
requires 'print_influences';
requires 'print_military_supports';
requires 'print_rebel_military_supports';
requires 'print_war_history';
requires 'print_turn_statistics';
requires 'print_formatted_turn_events';
requires 'print_nation_actual_situation';
requires 'print_borders_analysis';
requires 'print_near_analysis';
requires 'print_diplomacy';
requires 'print_nation_events';
requires 'pre_decisions_elaborations';
requires 'decisions';
requires 'post_decisions_elaborations';
requires 'print_market';



sub build_pre_statics
{
    my $self = shift;
    my $game = shift;
    my $site_root = $self->site_root;
    my $dest_dir = "$site_root/views/generated/$game/" . $self->current_year();
    make_path $dest_dir;
    open(my $hotspots, "> $dest_dir/hotspots.tt");
    print {$hotspots} $self->print_hotspots('html');  
    close($hotspots);
    open(my $allies, "> $dest_dir/alliances.tt");
    print {$allies} $self->print_allies(undef, 'html');  
    close($allies);
    open(my $influences, "> $dest_dir/influences.tt");
    print {$influences} $self->print_influences(undef, 'html');
    close($influences);
    open(my $supports, "> $dest_dir/supports.tt");
    print {$supports} $self->print_military_supports(undef, 'html');
    close($supports);
    open(my $reb_supports, "> $dest_dir/rebel-supports.tt");
    print {$reb_supports} $self->print_rebel_military_supports(undef, 'html');
    close($reb_supports);
    open(my $whistory, "> $dest_dir/war-history.tt");
    print {$whistory} $self->print_war_history('html');
    close($whistory);
    open(my $market, "> $dest_dir/market.tt");
    print {$market} $self->print_market('html');
    close($market);
    $self->build_nations_statics($game, $site_root);
}

sub build_post_statics
{
    my $self = shift;
    my $game = shift;
    my $site_root = $self->site_root;
    my $year = shift || $self->current_year;
    my $dest_dir = "$site_root/views/generated/$game/" . next_turn($year);
    make_path $dest_dir;
    open(my $situation, "> $dest_dir/situation.tt");
    print {$situation} $self->print_turn_statistics($year, undef, 'html');  
    close($situation);
    open(my $events, "> $dest_dir/events.tt"); 
    print {$events} $self->print_formatted_turn_events($year, undef, 'html');  
    close($events);
}

sub build_meta_statics
{
    my $self = shift;
    my $game = shift;
    my $site_root = $self->site_root;
    my $dest_dir = "$site_root/metadata";
    make_path $dest_dir;
    my %nations_to_dump;
    foreach my $n (@{$self->nations})
    {
        $nations_to_dump{$n->name} = {
                                 code => $n->code,
                                 area => $n->area };
    }
    my %data = ( current_year => $self->current_year,
                 nations => \%nations_to_dump );
    open(my $meta, "> $dest_dir/$game.meta");
    print {$meta} Dumper(\%data);
    close($meta);
}

sub build_nations_statics
{
    my $self = shift;
    my $game = shift;
    my $site_root = $self->site_root;
    foreach my $code (keys $self->nation_codes)
    {
        my $nation = $self->nation_codes->{$code};
        my $dest_dir = "$site_root/views/generated/$game/" . $self->current_year() . "/$code";
        make_path($dest_dir);
        open(my $status, "> $dest_dir/actual.tt");
        print {$status} $self->print_nation_actual_situation($nation, 1, 'html');
        close($status);
        open(my $borders, "> $dest_dir/borders.tt");
        print {$borders} $self->print_borders_analysis($nation, 'html');  
        close($borders);
        open(my $near, "> $dest_dir/near.tt");
        print {$near} $self->print_near_analysis($nation, 'html');  
        close($near);
        open(my $diplomacy, "> $dest_dir/diplomacy.tt");
        print {$diplomacy} $self->print_diplomacy($nation, 'html');  
        close($diplomacy);
        open(my $events, "> $dest_dir/events.tt");
        print {$events} $self->print_nation_events($nation, prev_turn($self->current_year()), undef, 'html');  
        close($events);
    }
}

sub generate_whole_turn
{
    my $self = shift;
    my $game = shift;
    my $turn = shift;
    my $site_root = shift;
    $self->pre_decisions_elaborations($turn);
    $self->build_pre_statics($game, $site_root);
    $self->decisions();
    $self->post_decisions_elaborations();
    $self->build_post_statics($game, $site_root);
}
sub generate_web_interactive_turn
{
    my $self = shift;
    my $game = shift;
    my $site_root = shift;
    $self->decisions();
    $self->post_decisions_elaborations();
    $self->build_post_statics($game, $site_root);
    $self->pre_decisions_elaborations(next_turn($self->current_year));
    $self->manage_web_players($game);
    $self->build_pre_statics($game, $site_root);
}

sub manage_web_players
{
    my $self = shift;
    my $game = shift;
    my $players = $self->get_web_data("/api/$game/users");
    if($players)
    {
        for(@{$players})
        {
            $self->create_player($_);
        }
    }

}

sub get_web_data
{
    my $self = shift;
    my $call = shift;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
    say "Getting data from " . $self->api_url . $call;
    my $response = $ua->get($self->api_url . $call);

    
    if ($response->is_success) {
        my $json = JSON->new->allow_nonref;
        return $json->decode( $response->decoded_content );
    }
    else {
        return undef;
    }
}

1;


