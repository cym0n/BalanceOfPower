package BalanceOfPower;
use v5.10;

use IO::Prompter;
use Data::Dumper;

use BalanceOfPower::Utils qw(next_turn get_year_turns compare_turns);
use BalanceOfPower::World;
use BalanceOfPower::Commands;
use Term::ANSIColor;

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
my $auto_years;

my $welcome_message = <<'WELCOME';
Welcome to Balance of Power, simulation of a real dangerous world!

Take the control of a country and try to make it the most powerful of the planet! 
WELCOME

use constant STUBBED_PLAYER => 1;



#Init
my $world = BalanceOfPower::World->new( first_year => $first_year );
$world->init_random(@nation_names);
init_game();
for($first_year..$first_year+$auto_years)
{
    my $y = $_;
    foreach my $t (get_year_turns($y))
    {
        elaborate_turn($t);
    }
}
say "=======\n\n\n";
interface();



sub init_game
{
    if(STUBBED_PLAYER)
    {
        $world->player_nation("Italy");
        $world->player("PlayerOne");
        $auto_years = 4;
    }
    else
    {
        say $welcome_message;
        my $player = prompt "Say your name, player: ";
        my $player_nation = prompt "Select the nation you want to control: ", -menu=>$world->nation_names;
        $world->player_nation($player_nation);
        $world->player($player);
        $auto_years = prompt "Tell a number of years to generate before game start: ", -i;
    }
}

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
    my $commands = BalanceOfPower::Commands->new( world => $world );
    $commands->init();
    while($commands->active)
    {
        my $result = 0;
        $commands->get_query();
        $result = $commands->turn_command();
        if($result)
        {
            elaborate_turn(next_turn($world->current_year));
            say $world->print_formatted_turn_events($world->current_year);
            next;
        }
        $result = $commands->report_commands();
    }

}





