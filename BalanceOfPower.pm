package BalanceOfPower;
use v5.10;

use IO::Prompter;
use Data::Dumper;

use BalanceOfPower::Utils qw(get_year_turns compare_turns);
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

#game
my $world = BalanceOfPower::World->new( first_year => $first_year );
$world->init_random(@nation_names);
my $commands = BalanceOfPower::Commands->new( world => $world );
my $auto_years = $commands->init_game();
$world->autoplay(1);
for($first_year..$first_year+$auto_years)
{
    my $y = $_;
    foreach my $t (get_year_turns($y))
    {
        $world->elaborate_turn($t);
    }
}
$world->autoplay(0);
#stubbed_situations();
say "=======\n\n\n";
interface();


sub interface
{
    $commands->init();
    $commands->welcome_player();
    while($commands->active)
    {
        my $result = undef;
        $commands->clear_query();
        $commands->get_query();
        $result = $commands->turn_command();
        if($result->{status} == 1)
        {
            $world->elaborate_turn();
            say $world->print_formatted_turn_events($world->current_year);
            next;
        }
        $result = $commands->report_commands();
        next if($result->{status} == 1);
        $result = $commands->orders();
        if($result->{status} == -1)
        {
            say "Command not allowed";
        }
        elsif($result->{status} == -2)
        {
            say "No options available";
        }
        
        elsif($result->{status} == 1)
        {
            say "Order selected: " . $result->{command};
            $world->order($result->{command});
        } 
    }

}



sub stubbed_situations
{
    $world->create_or_escalate_crisis("Italy", "Switzerland");
    $world->create_or_escalate_crisis("Italy", "Russia");
}




