package BalanceOfPower;
use v5.10;

use IO::Prompter;
use Data::Dumper;

use BalanceOfPower::Utils qw(next_turn get_year_turns);
use BalanceOfPower::World;

use strict;

unlink "bop.log";

#Initial status
my @nation_names = ("Italy", "France", "United Kingdom", "Russia", 
                    "Germany", "Spain", "Greece", "Switzerland", 
                    "Finland", "Sweden", "Norway", "Netherlands", 
                    "Belgium", "Portugal", "Denmark", "Austria",
                    "Czech Republic", "Slovakia", "Slovenia", "Hungary",
                    "Poland", "Turkey", "Bulgaria", "Albania" ); 
my $first_year = 1970;
my $last_year = 1972;

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



#Init
my $world = BalanceOfPower::World->new();
$world->init_random(@nation_names);

#History generation
for($first_year..$last_year)
{
    my $y = $_;
    foreach my $t (get_year_turns($y))
    {
        elaborate_turn($t);
    }
}
say "=======\n\n\n";
interface();

sub elaborate_turn
{
    my $t = shift;
    open(my $log, ">>", "bop.log");
    print $log "--- $t ---\n";
    close($log);
    $world->init_year($t);
    $world->war_debts();
    $world->crisis_generator();
    $world->execute_decisions();
    $world->economy();
    $world->warfare();
    $world->internal_conflict();
    $world->register_global_data();
    $world->collect_events();
}

sub interface
{
    my $continue = 1;
    my $query = undef;
    my $nation = undef;
    while($continue)
    {
        if(! $query)
        {
            my $prompt_text = $nation ? "($nation) ?" : "?";
            $prompt_text = "[Turn is " . $world->current_year . "]\n" . $prompt_text;
            $query = prompt $prompt_text;
        }
        while ($query =~ m/\x08/g) {
             substr($query, pos($query)-2, 2, '');
        }
        print "\n";
        if($query eq "quit") { $continue = 0 }
        elsif($query eq "turn")
        {
            $nation = undef;
            elaborate_turn(next_turn($world->current_year));
        }
        elsif($query eq "nations")
        {
            $query = prompt "?", -menu=>\@nation_names;
            $nation = undef;
            next;
        }
        elsif($query eq "years")
        {
            say "From $first_year/1 to " . $world->current_year; 
        }
        elsif($query eq "clear")
        {
            $nation = undef;
        }
        elsif($query eq "commands")
        {
            print $commands;
        }
        elsif($query eq "wars")
        {
            print $world->print_wars();
        }
        elsif($query eq "crises")
        {
            print $world->print_all_crises();
        }
        elsif($query eq "situation")
        {
           say $world->print_turn_statistics($world->current_year);  
        }
        elsif($query =~ /^((.*) )?borders$/)
        {
            my $input_nation = $2;
            if($input_nation)
            {
                $nation = $input_nation;
            }
            if($nation)
            {
                print $world->print_borders($nation);
            }
        }
        elsif($query =~ /^((.*) )?relations$/)
        {
            my $input_nation = $2;
            if($input_nation)
            {
                $nation = $input_nation;
            }
            if($nation)
            {
                print $world->print_diplomacy($nation);
            }
        }
        elsif($query =~ /^((.*) )?events( ((\d+)(\/\d+)?))?$/)
        {
            my $input_nation = $2;
            my $input_year = $4;
            $input_year ||= undef;
            if($input_nation)
            {
                $nation = $input_nation;
            }
            if($nation)
            {
                if($input_year)
                {
                    my @turns = get_year_turns($input_year); 
                    foreach my $t (@turns)
                    {
                        print $world->print_nation_events($nation, $t);
                            prompt "... press enter to continue ...\n\n" if($t ne $turns[-1]);
                    }
                }
                else
                {
                    print $world->print_nation_events($nation);
                }
            }
        }
        elsif($query =~ /^((.*) )?status$/)
        {
            my $input_nation = $2;
            if($input_nation)
            {
                $query = $input_nation;
                next;
            }
            elsif($nation)
            {
                $query = $nation;
                next;
            }
        }
        elsif($query =~ /^((.*) )?history$/)
        {
            my $input_nation = $2;
            if($input_nation)
            {
                $nation = $input_nation;
            }
            if($nation)
            {
                print $world->print_nation_statistics($nation, $first_year, $world->current_year);
            }
        }
        else
        {
            my @good_nation = grep { $_ eq $query } @nation_names; 
            if(@good_nation > 0) #it's a nation
            { 
                print $world->print_nation_actual_situation($query);
                $nation = $query;
            }
            else
            {
                my @good_year = ();
                if($query =~ /(\d+)(\/\d+)?/) #it's an year or a turn
                {
                    @good_year = grep { $_ eq $1 } ($first_year..$last_year);
                    if(@good_year > 0)
                    {
                        if($nation)
                        {
                            $query = "events $query";
                            next;
                        }
                        my @turns = get_year_turns($query); 
                        foreach my $t (@turns)
                        {
                            say $world->print_formatted_turn_events($t);
                            prompt "... press enter to continue ...\n" if($t ne $turns[-1]);
                        }
                    }
                }
                
            }
        }
        print "\n";
        $query = undef;
    }
}


