package BalanceOfPower;
use v5.10;

use IO::Prompt;

use BalanceOfPower::Utils qw(prev_year next_year random random10 get_year_turns);
use BalanceOfPower::World;

use strict;

#Initial status
my @nation_names = ("Italy", "France", "United Kingdom", "Russia", 
                    "Germany", "Spain", "Greece", "Switzerland", 
                    "Finland", "Sweden", "Norway", "Netherlands", 
                    "Belgium", "Portugal", "Denmark", "Austria",
                    "Czech Republic", "Slovakia", "Slovenia", "Hungary",
                    "Poland", "Turkey", "Bulgaria", "Albania" ); 
my $first_year = 1970;
my $last_year = 1995;

#Init
my $world = BalanceOfPower::World->new();
$world->init_random(@nation_names);

#History generation
for($first_year..$last_year)
{
    my $y = $_;
    foreach my $t (get_year_turns($y))
    {
        $world->init_year($t);
        $world->war_debts();
        $world->crisis_generator();
        $world->execute_decisions();
        $world->economy();
        $world->warfare();
        $world->internal_conflict();
        $world->register_global_data();
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
    while($continue)
    {
        my $query = prompt "?";
        if($query eq "quit") { $continue = 0 }
        elsif($query eq "overall")
        {
            say $world->print_overall_statistics($first_year, $last_year, @nation_names);
        }
        elsif($query eq "nations")
        {
            for(@nation_names) {say $_} ;
        }
        elsif($query eq "years")
        {
            say "From $first_year to $last_year";
        }
        elsif($query eq "commands")
        {
            say $commands;
        }
        elsif($query =~ m/history:(.*)/)
        {
            my @good_nation = grep { $_ eq $1 } @nation_names; 
            if(@good_nation > 0)
            { 
                say $good_nation[0] . " - HISTORY";
                say "=====\n";
                say $world->print_nation_statistics($good_nation[0], $first_year, $last_year);
            }
        }
        elsif($query =~ m/status:(.*)/)
        {
            my @good_nation = grep { $_ eq $1 } @nation_names; 
            if(@good_nation > 0)
            { 
                say $good_nation[0] . " - STATUS";
                say "=====\n";
                say $world->print_nation($good_nation[0]);
            }
        }
        elsif($query =~ m/diplomacy:(.*)/)
        {
            my @good_nation = grep { $_ eq $1 } @nation_names; 
            if(@good_nation > 0)
            { 
                say $world->print_diplomacy($good_nation[0]);
            }
        }
        elsif($query =~ m/borders:(.*)/)
        {
            my @good_nation = grep { $_ eq $1 } @nation_names; 
            if(@good_nation > 0)
            { 
                say $world->print_borders($good_nation[0]);
            }
        }
        elsif($query =~ m/crises/)
        {
            foreach my $y ($first_year..$last_year)
            {
                print $world->print_crises($y);
            }
            print "\n";
            print $world->print_defcon_statistics($first_year, $last_year);
        }
        else
        {
            my @good_nation = grep { $_ eq $query } @nation_names; 
            my @good_year = grep { $_ eq $query } ($first_year..$last_year);
            if(@good_nation > 0)
            { 
                say "\n=====\n";
                say $world->print_nation($query);
                say $world->print_nation_statistics($query, $first_year, $last_year);
            }
            elsif(@good_year > 0)
            {
                say $world->print_year_statistics($query, @nation_names);
            }
        }
    }
}


