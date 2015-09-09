package BalanceOfPower::Commands;

use v5.10;
use Moo;
use IO::Prompter;
use Term::ANSIColor;
use BalanceOfPower::Utils qw(next_turn get_year_turns compare_turns);
use BalanceOfPower::Commands::Plain;
use BalanceOfPower::Commands::DeclareWar;
use BalanceOfPower::Commands::TargetRoute;

has world => (
    is => 'ro'
);

has commands => (
    is => 'rw',
    default => sub { [] }
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
    my $command = 
        BalanceOfPower::Commands::Plain->new( name => "BUILD TROOPS",
                                              world => $self->world,
                                              allowed_at_war => 1 );
    push @{$self->commands}, $command; 
    $command = 
        BalanceOfPower::Commands::Plain->new( name => "LOWER DISORDER",
                                              world => $self->world );
    push @{$self->commands}, $command; 
    $command = 
        BalanceOfPower::Commands::Plain->new( name => "ADD ROUTE",
                                              world => $self->world );
    push @{$self->commands}, $command; 
    $command =
        BalanceOfPower::Commands::DeclareWar->new( name => "DECLARE WAR TO",
                                                 synonyms => ["DECLARE WAR"],
                                                 world => $self->world );
    push @{$self->commands}, $command; 
    $command =
        BalanceOfPower::Commands::TargetRoute->new( name => "DELETE TRADEROUTE",
                                                 world => $self->world );
    push @{$self->commands}, $command; 
}

sub print_orders
{
    my $self = shift;
    my $out = "";
    foreach my $c (@{$self->commands})
    {
        $out .= $c->print . "\n";
    }
    return $out;
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
        $self->world->player_nation("Italy");
        $self->world->player("PlayerOne");
        $auto_years = 1;
    }
    else
    {
        say $welcome_message;
        my $player = prompt "Say your name, player: ";
        my $player_nation = prompt "Select the nation you want to control: ", -menu=>$self->world->nation_names;
        $self->world->player_nation($player_nation);
        $self->world->player($player);
        $auto_years = prompt "Tell a number of years to generate before game start: ", -i;
    }
    return $auto_years;
}



sub welcome_player
{
    my $self = shift;
    print $self->world->print_nation_actual_situation($self->world->player_nation);
    print "\n";
}

sub get_query
{
    my $self = shift;
    return if($self->query);
    my $prompt_text = "[" . $self->world->player . ", leader of " . $self->world->player_nation . ". Turn is " . $self->world->current_year . "]\n";
    if($self->world->order)
    {
        $prompt_text .= "=== ORDER SELECTED: " . $self->world->order . "\n";
    }
    $prompt_text .= $self->nation ? "(" . $self->nation . ") ?" : "?";
    print color("cyan");
    my $input_query = prompt $prompt_text;
    $input_query .= "";
    print color("reset");
    while ($input_query =~ m/\x08/g) {
        substr($input_query, pos($input_query)-2, 2, '');
    }
    print "\n";
    $self->query($input_query);
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
<relations>
<events>
<status>
<history>
[year/turn]

You can also say one of these as: [nation name] [command]

[year/turn] with no nation selected gives all the events of the year/turns

say <years> for available range of years

say <wars> for a list of wars, <crises> for all the ongoing crises

say <turn> to elaborate events for a new turn
COMMANDS

    my $result = { status => 0 };

    if($query eq "quit") { $self->active(0); $result = 1 }
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
    elsif($query eq "commands")
    {
        print $commands;
        $result = { status => 1 };
    }
     elsif($query eq "orders")
    {
        print $self->print_orders();;
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
    elsif($query eq "situation")
    {
        say $self->world->print_turn_statistics($self->world->current_year);  
        $result = { status => 1 };
    }
    elsif($query =~ /^((.*) )?borders$/)
    {
        my $input_nation = $2;
        if($input_nation)
        {
            $self->nation($input_nation);
        }
        if($self->nation)
        {
           print $self->world->print_borders($self->nation);
        }
        $result = { status => 1 };
    }
    elsif($query =~ /^((.*) )?relations$/)
    {
        my $input_nation = $2;
        if($input_nation)
        {
            $self->nation($input_nation);
        }
        if($self->nation)
        {
            print $self->world->print_diplomacy($self->nation);
        }
        $result = { status => 1 };
    }
    elsif($query =~ /^((.*) )?events( ((\d+)(\/\d+)?))?$/)
    {
        my $input_nation = $2;
        my $input_year = $4;
        $input_year ||= undef;
        if($input_nation)
        {
            $self->nation($input_nation);
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
            }
            else
            {
                print $self->world->print_nation_events($self->nation);
            }
        }
        else
        {
            say $self->world->print_formatted_turn_events($self->world->current_year);
        }
        $result = { status => 1 };
    }
    elsif($query =~ /^((.*) )?status$/)
    {
        my $input_nation = $2;
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
        my $input_nation = $2;
        if($input_nation)
        {
            $self->nation($input_nation);
        }
        if($self->nation)
        {
            print $self->world->print_nation_statistics($self->nation, $self->world->first_year, $self->world->current_year);
        }
        $result = { status => 1 };
    }
    else
    {
        my @good_nation = grep { $query  =~ /$_/ } @{$self->world->nation_names};
        if(@good_nation > 0) #it's a nation
        { 
            print $self->world->print_nation_actual_situation($query);
            $self->nation($query);
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

sub orders
{
    my $self = shift;
    my $query = $self->query;
    foreach my $c (@{$self->commands})
    {
        if($c->recognize($query))
        {
            if($c->allowed())
            {
                return $c->execute($query, $self->nation);
            }
            else
            {
                return { status => -1 };
            }
        }
    }
    return { status => 0 };
}

1;
