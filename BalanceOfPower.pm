package BalanceOfPower;
use v5.10;

use IO::Prompter;
use Data::Dumper;

use BalanceOfPower::Utils qw(prev_year next_year random random10 get_year_turns);
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

#Init
my $world = BalanceOfPower::World->new();
$world->init_random(@nation_names);

#History generation
for($first_year..$last_year)
{
    my $y = $_;
    foreach my $t (get_year_turns($y))
    {
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
}
say "=======\n\n\n";
interface();

sub interface
{
    my $commands = "Commands are:\n    nations, years,\n    history:[nation name], status:[nation name], diplomacy:[nation name], borders:[nation name]\n    crises,\n    [year], overall,\n    commands, quit";
    say "Retrieve informations about history";
    say $commands;
    my $continue = 1;
    my $query = undef;
    my $nation = undef;
    while($continue)
    {
        if(! $query)
        {
            my $prompt_text = $nation ? "($nation) ?" : "?";
            $query = prompt $prompt_text;
        }
        while ($query =~ m/\x08/g) {
             substr($query, pos($query)-2, 2, '');
        }
        if($query eq "quit") { $continue = 0 }
        elsif($query eq "nations")
        {
            $query = prompt "?", -menu=>\@nation_names;
            $nation = undef;
            next;
        }
        elsif($query eq "years")
        {
            say "From $first_year to $last_year";
            $nation = undef;
        }
        elsif($query eq "situation")
        {
           say $world->print_turn_statistics($world->current_year, @nation_names);  
        }
        elsif($query =~ /^((.*) )?borders$/)
        {
            my $input_nation = $2;
            if($input_nation)
            {
                say $world->print_borders($input_nation);
                $nation = $input_nation;
            }
            elsif($nation)
            {
                say $world->print_borders($nation);
            }
        }
        elsif($query =~ /^((.*) )?relations$/)
        {
            my $input_nation = $2;
            if($input_nation)
            {
                say $world->print_diplomacy($input_nation);
                $nation = $input_nation;
            }
            elsif($nation)
            {
                say $world->print_diplomacy($nation);
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
            if($input_year)
            {
                my @turns = get_year_turns($input_year); 
                foreach my $t (@turns)
                {
                    say $world->print_nation_events($nation, $t);
                        prompt "... press enter to continue ...\n" if($t ne $turns[-1]);
                }
            }
            else
            {
                say $world->print_nation_events($nation);
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
            say $world->print_nation_statistics($nation, $first_year, $world->current_year);
        }
        else
        {
            my @good_nation = grep { $_ eq $query } @nation_names; 
            if(@good_nation > 0) #it's a nation
            { 
                say $world->print_nation_actual_situation($query);
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
                        my @turns = get_year_turns($query); 
                        foreach my $t (@turns)
                        {
                            say $world->print_formatted_turn_events($t, @nation_names);
                            prompt "... press enter to continue ...\n" if($t ne $turns[-1]);
                        }
                        $nation = undef;
                    }
                }
                
            }
        }
        $query = undef;


        ### TO REVEW       
        
        
        
        
        
#        elsif($query eq "overall")
#        {
#            say $world->print_overall_statistics($first_year, $last_year, @nation_names);
#        }
#        elsif($query eq "commands")
#        {
#            say $commands;
#        }
#        elsif($query =~ m/history:(.*)/)
#        {
#            my @good_nation = grep { $_ eq $1 } @nation_names; 
#            if(@good_nation > 0)
#            { 
#                say $good_nation[0] . " - HISTORY";
#                say "=====\n";
#                say $world->print_nation_statistics($good_nation[0], $first_year, $last_year);
#            }
#        }
#        elsif($query =~ m/status:(.*)/)
#        {
#            my @good_nation = grep { $_ eq $1 } @nation_names; 
#            if(@good_nation > 0)
#            { 
#                say $good_nation[0] . " - STATUS";
#                say "=====\n";
#                say $world->print_nation($good_nation[0]);
#            }
#        }
#        elsif($query =~ m/diplomacy:(.*)/)
#        {
#            my @good_nation = grep { $_ eq $1 } @nation_names; 
#            if(@good_nation > 0)
#            { 
#                say $world->print_diplomacy($good_nation[0]);
#            }
#        }
#        elsif($query =~ m/borders:(.*)/)
#        {
#            my @good_nation = grep { $_ eq $1 } @nation_names; 
#            if(@good_nation > 0)
#            { 
#                say $world->print_borders($good_nation[0]);
#            }
#        }
#        elsif($query =~ m/crises/)
#        {
#            foreach my $y ($first_year..$last_year)
#            {
#                print $world->print_crises($y);
#            }
#            print "\n";
#            print $world->print_defcon_statistics($first_year, $last_year);
#        }
     
    }
}


