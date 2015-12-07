package BalanceOfPower::Commands;

use v5.10;
use Moo;
use IO::Prompter;
use Term::ANSIColor;
use BalanceOfPower::Executive;
use BalanceOfPower::Constants ":all";
use BalanceOfPower::Utils qw(next_turn prev_turn get_year_turns compare_turns evidence_text);

with 'BalanceOfPower::Role::Logger';

has world => (
    is => 'ro'
);
has executive => (
    is => 'ro',
    default => sub { BalanceOfPower::Executive->new; },           
    handles => { recognize_command => 'recognize_command',
                 print_orders => 'print_orders'
               }
);
has query => (
    is => 'rw',
    default => "" 
);
has keep_query => (
    is => 'rw',
    default => 0 
);
has nation => (
    is => 'rw',
    default => ""
);
has active => (
    is => 'rw',
    default => 1
);

sub init
{
    my $self = shift;
    $self->executive->init($self->world);
}






sub init_game
{
    my $self = shift;
    my $stubbed = shift;

    my $welcome_message = <<'WELCOME';
Welcome to Balance of Power, simulation of a real dangerous world!

Take the control of a country and try to make it the most powerful of the planet! 
WELCOME

    my $auto_years;
    if($stubbed)
    {
        $self->set_player_nation("Italy");
        $self->world->player("PlayerOne");
        $auto_years = 10;
    }
    else
    {
        say $welcome_message;
        my $player = prompt "Say your name, player: ";
        my $player_nation = prompt "Select the nation you want to control: ", -menu=>$self->world->nation_names;
        $self->world->player($player);
        $self->set_player_nation($player_nation);
        $auto_years = prompt "Tell a number of years to generate before game start: ", -i;
    }
    return $auto_years;
}
sub set_player_nation
{
    my $self = shift;
    my $player_nation = shift;
    $self->world->player_nation($player_nation);
    $self->executive->actor($player_nation);
}


sub welcome_player
{
    my $self = shift;
    print $self->world->print_nation_actual_situation($self->world->player_nation);
    print "\n";
}
sub get_prompt_text
{
    my $self = shift;
    my $prompt_text = "[" . $self->world->player . ", leader of " . $self->world->player_nation . ". Turn is " . $self->world->current_year . "]\n";
    my $nation  = $self->world->get_player_nation();
    $prompt_text .= "Int:" . $nation->production_for_domestic . "    Exp:" . $nation->production_for_export . "    Prtg:" . $nation->prestige . "    Army:" . $nation->army . "\n";
    if($self->world->order)
    {
        $prompt_text .= "=== ORDER SELECTED: " . $self->world->order . "\n";
    }
    $prompt_text .= $self->nation ? "(" . $self->nation . ") ?" : "?";
    return $prompt_text;
}

sub get_query
{
    my $self = shift;
    if($self->query)
    {
        $self->log("[Not interactive query] " . $self->query);
        return;
    }
    print color("cyan");
    my $input_query = prompt $self->get_prompt_text();
    $input_query .= "";
    print color("reset");
    while ($input_query =~ m/\x08/g) {
        substr($input_query, pos($input_query)-2, 2, '');
    }
    print "\n";
    $self->query($input_query);
    $self->log("[Interactive query] " . $self->query);
}

sub clear_query
{
    my $self = shift;
    if($self->keep_query)
    {
        $self->keep_query(0);
    }
    else
    {
        $self->query(undef);
    }
}

sub turn_command
{
    my $self = shift;
    my $query = $self->query;
    if($query eq "turn")
    {
        $self->nation(undef);
        $self->query(undef);
        return { status => 1 };
    }
    else
    {
        return { status => 0 };
    }
}

sub report_commands
{
    my $self = shift;
    my $query = $self->query;

    my $commands = <<'COMMANDS';
Say the name of a nation to select it and obtain its status.
Say <nations> for the full list of nations.
Say <clear> to un-select nation.

With a nation selected you can use:
<borders>
<near>
<relations>
<events>
<status>
<history>
[year/turn]
You can also say one of those commands as: [nation name] [command]

[year/turn] with no nation selected gives all the events of the year/turns

say <years> for available range of years

say <wars> for a list of wars, <crises> for all the ongoing crises

say <hotspots> gives you wars and crises with also your diplomatic relationship with countries involved

say <supports> for military supports

say <distance NATION1-NATION2> for distance between nations

say <turn> to elaborate events for a new turn

<orders> display a list of command you can give to your nation for the next turn

<clearorders> nullify the command issued for the next turn    
COMMANDS

    my $result = { status => 0 };

    $query = lc $query;

    if($query eq "quit") { $self->active(0); $result = { status => 1 }; }
    elsif($query eq "nations")
    {
        $query = prompt "?", -menu=>$self->world->nation_names;
        $self->nation(undef);
        $self->keep_query(1);
        $result = { status => 1 };
    }
    elsif($query eq "years")
    {
        say "From " . $self->world->first_year . "/1 to " . $self->world->current_year; 
        $result = { status => 1 };
    }
    elsif($query eq "clear")
    {
        $self->nation(undef);
        $result = { status => 1 };
    }
    elsif($query eq "clearorders")
    {
        $self->nation(undef);
        $self->world->order(undef);
        $result = { status => 1 };
    }
    elsif($query eq "commands")
    {
        print $commands;
        $result = { status => 1 };
    }
     elsif($query eq "orders")
    {
        print $self->print_orders($self->world->player_nation);;
        $result = { status => 1 };
    }
    elsif($query eq "wars")
    {
        print $self->world->print_wars();
        $result = { status => 1 };
    }
    elsif($query eq "crises")
    {
        print $self->world->print_all_crises();
        $result = { status => 1 };
    }
    elsif($query eq "alliances")
    {
        print $self->world->print_allies();
        $result = { status => 1 };
    }
    elsif($query eq "hotspots")
    {
        print $self->world->print_hotspots();
        $result = { status => 1 };
    }
    elsif($query eq "war history")
    {
        print $self->world->print_war_history();
        $result = { status => 1 };
    }

    elsif($query =~ /^situation( (.*))?$/)
    {
        my $order = $2;
        say $self->world->print_turn_statistics($self->world->get_prev_year(), $order);  
        $result = { status => 1 };
    }
    elsif($query eq "supports")
    {
        say $self->world->print_military_supports();  
        $result = { status => 1 };
    }
    elsif($query =~ /^distance (.*)-(.*)$/)
    {
        my $n1 = $self->world->correct_nation_name($1);
        my $n2 = $self->world->correct_nation_name($2);
        if($self->verify_nation($n1) && $self->verify_nation($n2))
        {
            say $self->world->print_distance($n1, $n2);
            $result = { status => 1 };
        }
    }
    elsif($query =~ /^((.*) )?borders$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        if($input_nation)
        {
            $self->nation($input_nation);
        }
        if(! $self->nation)
        {
            $self->nation($self->world->player_nation);
        }
        #print $self->world->print_borders($self->nation);
        print $self->world->print_borders_analysis($self->nation);
        $result = { status => 1 };
    }
    elsif($query =~ /^((.*) )?near$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        if($input_nation)
        {
            $self->nation($input_nation);
        }
        if(! $self->nation)
        {
            $self->nation($self->world->player_nation);
        }
        #print $self->world->print_near_nations($self->nation);
        print $self->world->print_near_analysis($self->nation);
        $result = { status => 1 };
    }
    elsif($query =~ /^((.*) )?relations$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        if($input_nation)
        {
            $self->nation($input_nation);
        }
        if(! $self->nation)
        {
            $self->nation($self->world->player_nation);
        }
        print $self->world->print_diplomacy($self->nation);
        $result = { status => 1 };
    }
    elsif($query =~ /^((.*) )?events( ((\d+)(\/\d+)?))?$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        my $input_year = $4;
        $input_year ||= undef;
        if($input_nation)
        {
            $self->nation($input_nation);
        }
        if(! $self->nation)
        {
            $self->nation($self->world->player_nation);
        }
        if($self->nation)
        {
            if($input_year)
            {
                my @turns = get_year_turns($input_year); 
                foreach my $t (@turns)
                {
                    print $self->world->print_nation_events($self->nation, $t);
                    my $wait = prompt "... press enter to continue ...\n\n" if($t ne $turns[-1]);
                }
                $result = { status => 1 };
            }
            else
            {
                print $self->world->print_nation_events($self->nation, prev_turn($self->world->current_year) );
                $result = { status => 1 };
            }
        }
        else
        {
            if($input_year)
            {
                $query = $input_year;
                $self->keep_query(1);
                $result = { status => 1 };
            } 
        }
    }
    elsif($query =~ /^((.*) )?status$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        if($input_nation)
        {
            $query = $input_nation;
            $self->keep_query(1);
        }
        elsif($self->nation)
        {
           $query = $self->nation;
           $self->keep_query(1);
        }
        $result = { status => 1 };
    }
    elsif($query =~ /^((.*) )?history$/)
    {
        my $input_nation = $self->world->correct_nation_name($2);
        if($input_nation)
        {
            $self->nation($input_nation);
        }
        if(! $self->nation)
        {
            $self->nation($self->world->player_nation);
        }
        print $self->world->print_nation_statistics($self->nation, $self->world->first_year, $self->world->current_year);
        $result = { status => 1 };
    }
    else
    {
        my $nation_query = $self->world->correct_nation_name($query);
        if($self->verify_nation($nation_query)) #it's a nation
        { 
            print $self->world->print_nation_actual_situation($nation_query, 1);
            $self->nation($nation_query);
            $result = { status => 1 };
        }
        else
        {
            my @good_year = ();
            if($query =~ /(\d+)(\/\d+)?/) #it's an year or a turn
            {
                if((compare_turns($query, $self->world->current_year) == 0 || compare_turns($query, $self->world->current_year) == -1) &&
                    compare_turns($query, $self->world->first_year) >= 0)
                {
                    if($self->nation)
                    {
                        $query = "events $query";
                        $self->keep_query(1);
                        $result = { status => 1 };
                    }
                    else
                    {
                        my @turns = get_year_turns($query); 
                        foreach my $t (@turns)
                        {
                            say $self->world->print_formatted_turn_events($t);
                            my $wait = prompt "... press enter to continue ...\n" if($t ne $turns[-1]);
                        }
                        $result = { status => 1 };
                    }
                }
            }
        }
    }
    print "\n";
    $self->query($query);
    return $result;
}
sub verify_nation
{
    my $self = shift;
    my $query = shift;
    return 0 if (! $query);
    my @good_nation = grep { $query  =~ /^$_$/ } @{$self->world->nation_names};
    return @good_nation > 0;
}
sub orders
{
    my $self = shift;
    return $self->recognize_command($self->nation,
                                    $self->query);
    
}

sub interact
{
    my $self = shift;
    $self->world->pre_decisions_elaborations();
    while($self->active)
    {
        my $result = undef;
        $self->clear_query();
        $self->get_query();
        $result = $self->turn_command();
        if($result->{status} == 1)
        {
            say "Elaborating " . $self->world->current_year . "...\n";
            $self->world->post_decisions_elaborations();
            say evidence_text($self->world->print_formatted_turn_events($self->world->current_year), $self->world->player_nation);
            $self->world->pre_decisions_elaborations();
            next;
        }
        $result = $self->report_commands();
        next if($result->{status} == 1);
        $result = $self->orders();
        if($result->{status} == -1)
        {
            say "Command not allowed";
        }
        elsif($result->{status} == -2)
        {
            say "No options available";
        }
        elsif($result->{status} == -3)
        {
            say "Command aborted";
        }
        elsif($result->{status} == 1)
        {
            say "Order selected: " . $result->{command};
            $self->world->order($result->{command});
        } 
    }
}


1;
