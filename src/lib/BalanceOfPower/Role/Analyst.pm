package BalanceOfPower::Role::Analyst;

use strict;
use v5.10;
use Moo::Role;
use Term::ANSIColor;
use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw( prev_turn as_title as_title as_subtitle compare_turns);
use BalanceOfPower::Printer;

requires 'diplomacy_exists';
requires 'get_borders';
requires 'supported';
requires 'exists_military_support';
requires 'near_nations';
requires 'routes_for_node';
requires 'get_allies';
requires 'get_crises';
requires 'get_wars';
requires 'print_nation_situation';
requires 'print_nation_statistics_header';
requires 'print_nation_statistics_line';
requires 'get_player';
requires 'print_all_crises';
requires 'print_wars';

sub print_nation_actual_situation
{
    my $self = shift;
    my $nation = shift;
    my $in_the_middle = shift;
    my $mode = shift || 'print';
    my $attributes_names = ["Size", "Prod.", "Wealth", "W/D", "Growth", "Disor.", "Army", "Prog.", "Pstg."];
    my $attributes = ["production", "wealth", "w/d", "growth", "internal disorder", "army", "progress", "prestige"];

    my $turn;
    if($in_the_middle)
    {
        $turn = prev_turn($self->current_year);
    }
    else
    {
        $turn = $self->current_year;
    }
    my $nation_obj = $self->get_nation($nation);
    my $under_influence = $self->is_under_influence($nation);
    my @influence = $self->has_influence($nation);
    my @ndata = $self->get_nation_statistics_line($nation, $turn, $attributes);
    my @routes = $self->routes_for_node($nation);
    my @treaties = $self->get_treaties_for_nation($nation);
    my @supports = $self->supports($nation);
    my @rebel_supports = $self->rebel_supports($nation);
    my $first_row_height;
    if(@treaties > @supports + @rebel_supports)
    {
        $first_row_height = @treaties;
    }
    else
    {
        $first_row_height = @supports + @rebel_supports;
    }
    my @crises = $self->get_crises($nation);
    my @wars = $self->get_wars($nation);
    my $second_row_height;
    if(@crises > @wars)
    {
        $second_row_height = @crises;
    }
    else
    {
        $second_row_height = @wars;
    }
    my $latest_order = $self->get_statistics_value($turn, $nation, 'order') ? $self->get_statistics_value($turn, $nation, 'order') : 'NONE';
    return BalanceOfPower::Printer::print($mode, $self, 'print_actual_nation_situation', 
                                   { nation => $nation_obj,
                                     under_influence => $under_influence,
                                     influence => \@influence,
                                     attributes => $attributes_names,
                                     nationstats => \@ndata,
                                     traderoutes => \@routes,
                                     treaties => \@treaties,
                                     supports => \@supports,
                                     rebel_supports => \@rebel_supports,
                                     first_row_height => $first_row_height,
                                     crises => \@crises,
                                     wars => \@wars,
                                     second_row_height => $second_row_height,
                                     latest_order => $latest_order,
                                   } );
}

sub print_borders_analysis
{
    my $self = shift;
    my $nation = shift;
    my $mode = shift || 'print';
    my @borders = $self->near_nations($nation, 1);
    my %data;

    foreach my $b (@borders)
    {
        my $rel = $self->diplomacy_exists($nation, $b);
        $data{$b}->{'relation'} = $rel;

        my $supps = $self->supported($b);
        if($supps)
        {
            my $supporter = $supps->start($b);
            $data{$b}->{'support'}->{nation} = $supporter;
            my $sup_rel = $self->diplomacy_exists($nation, $supporter);
            $data{$b}->{'support'}->{relation} = $sup_rel;
        }
    }
    return BalanceOfPower::Printer::print($mode, $self, 'print_borders_analysis', 
                                   { nation => $nation,
                                     borders => \%data } );

}
sub print_near_analysis
{
    my $self = shift;
    my $nation = shift;
    my $mode = shift || 'print';
    my @data = ();
    my @near = $self->near_nations($nation, 0);
    foreach my $b (@near)
    {
        my $rel = $self->diplomacy_exists($nation, $b);
        if(! $self->border_exists($nation, $b))
        {
            if($self->exists_military_support($nation, $b))
            {
                push @data, { nation => $b,
                              relation => $rel,
                              how => 'Supported' };
            }
            else
            {
                my @foreign_borders = $self->get_borders($b);
                foreach my $fb (@foreign_borders)
                {
                    my $other_n = $fb->destination($b);
                    my $sups = $self->supported($other_n);
                    if($sups)
                    {
                        if($sups->start($other_n) eq $nation)
                        {
                            push @data, { nation => $b,
                                          relation => $rel,
                                          how => "Military support from $other_n" };
                        }
                    }
                }
            }
        }
        else
        {
            push @data, { nation => $b,
                          relation => $rel,
                          how => "border" };
        }
    }
    BalanceOfPower::Printer::print($mode, $self, 'print_near_analysis', 
                                           { nation => $nation,
                                             near => \@data } );

}
sub print_hotspots
{
     my $self = shift;
     my $mode = shift || 'print';
     my $out = "";
     $out .= $self->print_all_crises(undef, 1, $mode);
     $out .= $self->print_wars(undef, $mode);
     return $out;
}

sub print_civil_war_report
{
    my $self = shift;
    my $nation = shift;
    if (! $self->at_civil_war($nation))
    {
        return "$nation is not fightinh civil war";
    }
    my $out = "";
    my $nation_obj = $self->get_nation($nation);
    $out .= "Rebel provinces: " . $nation_obj->rebel_provinces . "/" . PRODUCTION_UNITS->[$nation_obj->size] . "\n";
    $out .= "Army: " . $nation_obj->army . "\n";
    my $sup = $self->supported($nation);
    my $rebsup = $self->rebel_supported($nation);
    $out .= "Support: " . $sup->print . "\n" if($sup);
    $out .= "Rebel support: " . $rebsup->print . "\n" if ($rebsup);
    return $out;
}

sub print_war_history
{
    my $self = shift;
    my $mode = shift || 'print';
    my %wars;
    my @war_names;
    foreach my $w (@{$self->memorial})
    {
        if(exists $wars{$w->war_id})
        {
           push @{$wars{$w->war_id}}, $w;
        }
        else
        {
           $wars{$w->war_id} =  [ $w ];
           push @war_names, { name => $w->war_id,
                              start => $w->start_date  };
        }
    }
    sub comp
    {
        compare_turns($a->{start}, $b->{start});
    }
    @war_names = sort comp @war_names;
    return BalanceOfPower::Printer::print($mode, $self, 'print_war_history', 
                                   { wars => \%wars,
                                     war_names => \@war_names } );
}
sub print_treaties_table
{
    my $self = shift;
    my $out = sprintf "%-20s %-6s %-5s %-5s %-5s", "Nation", "LIMIT", "ALL", "NAG", "COM";
    $out .= "\n";
    my @nations = @{$self->nation_names};
    for(@nations)
    {
        my $n = $_;
        my $limit = $self->get_nation($n)->treaty_limit;
        my $alls = $self->get_treaties_for_nation_by_type($n, 'alliance');
        my $coms = $self->get_treaties_for_nation_by_type($n, 'commercial');
        my $nags = $self->get_treaties_for_nation_by_type($n, 'no aggression');
        $out .= sprintf "%-20s %-6s %-5s %-5s %-5s", $n, $limit, $alls, $nags, $coms;
        $out .= "\n";
    }
    return $out;
}
sub print_stocks
{
    my $self = shift;
    my $player = shift;
    my $player_obj = $self->get_player($player);
    my $stock_value = 0;
    my $out = "";
    $out .= as_title(sprintf "%-15s %-10s %-10s %-10s %-10s", "NATION", "Q", "VALUE", "INFLUENCE", "WAR BONDS");
    $out .= "\n";
    foreach my $nation(keys %{$player_obj->wallet})
    {
        if( $player_obj->stocks($nation) > 0 || $player_obj->influence($nation) > 0)
        {
            $out .= sprintf "%-15s %-10s %-10s %-10s %-10s", $nation, $player_obj->wallet->{$nation}->{stocks}, $self->get_statistics_value(prev_turn($self->current_year), $nation, "w/d"), $player_obj->wallet->{$nation}->{influence}, $player_obj->wallet->{$nation}->{'war bonds'} ;
            $out .= "\n";
            $stock_value += $player_obj->wallet->{$nation}->{stocks} * $self->get_statistics_value(prev_turn($self->current_year), $nation, "w/d");
        }
    }
    $out .= "\n";
    $out .= "Stock value: " . $stock_value . "\n";
    $out .= "Money: " . $player_obj->money . "\n";
    my $total_value = $stock_value + $player_obj->money;
    $out .= "Total value: " . $total_value . "\n";
    return $out;
}
sub print_market
{
    my $self = shift;
    my $out = "";
    $out .= as_title(sprintf "%-20s %-10s %-10s %-10s", "NATION", "STOCK", "VALUE", "STATUS");
    $out .= "\n";
    my @ordered = $self->order_statistics(prev_turn($self->current_year), 'w/d');
    foreach my $stats (@ordered)
    {
        my $nation = $self->get_nation($stats->{nation});
        my $status = "";
        if($self->at_war($nation->name))
        {
            $status = "WAR";
        }
        elsif($self->at_civil_war($nation->name))
        {
            $status = "CIVILW";
        }
        $out .= sprintf "%-20s %-10s %-10s %-10s", $nation->name, $nation->available_stocks, $stats->{value}, $status;
        $out .= "\n";
    }
    return $out;
}
1;
