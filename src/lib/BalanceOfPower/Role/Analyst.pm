package BalanceOfPower::Role::Analyst;

use strict;
use v5.10;
use Moo::Role;
use Term::ANSIColor;
use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw( prev_turn as_title as_title as_subtitle );

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

sub print_nation_actual_situation
{
    my $self = shift;
    my $nation = shift;
    my $in_the_middle = shift;
    my $turn = shift;
    if($in_the_middle)
    {
        $turn = prev_turn($self->current_year);
    }
    else
    {
        $turn = $self->current_year;
    }
    my $nation_obj = $self->get_nation($nation);
    my $out = as_title("$nation\n===\n");
    $out .= $nation_obj->print_attributes();
    $out .= "\n";
    $out .= $self->print_nation_situation($nation);
    $out .= "\n";
    $out .= "\n";
    $out .= $self->print_nation_statistics_header() . "\n";
    $out .= $self->print_nation_statistics_line($nation, $turn) . "\n\n";
    $out .= as_title("TRADEROUTES\n---\n");
    foreach my $tr ($self->routes_for_node($nation))
    {
        $out .= $tr->print($nation) . "\n";
    }
    $out .= "\n";
    my $allies_support_title = sprintf "%-35s %-35s", "TREATIES", "SUPPORTS";
    $allies_support_title .="\n";
    $allies_support_title .= sprintf "%-35s %-35s", "---", "---";
    $allies_support_title .="\n";
    $out .= as_title($allies_support_title);
    my @allies = $self->get_treaties_for_nation($nation);
    my @supports = $self->supports($nation);
    for(my $i = 0; ;$i++)
    {
        last if(@allies == 0 && @supports == 0);
        my $allies_text = "";
        if(@allies)
        {
            my $a = shift @allies;
            $allies_text = $a->print;
        }
        my $support_text = "";
        if(@supports)
        {
            my $s = shift @supports;
            $support_text = $s->print;
        }
        $out .= sprintf "%-35s %-35s", $allies_text, $support_text;
        $out .="\n";
    }
    $out .= "\n";
    my $crises_wars_title = sprintf "%-35s %-35s", "CRISES", "WARS";
    $crises_wars_title .="\n";
    $crises_wars_title .= sprintf "%-35s %-35s", "---", "---";
    $crises_wars_title .="\n";
    $out .= as_title($crises_wars_title);
    my @crises = $self->get_crises($nation);
    my @wars = $self->get_wars($nation);
    for(my $i = 0; ;$i++)
    {
        last if(@crises == 0 && @wars == 0);
        my $crisis_text = "";
        if(@crises)
        {
            my $c = shift @crises;
            $crisis_text = $c->print_crisis;
        }
        my $war_text = "";
        if(@wars)
        {
            my $w = shift @wars;
            $war_text = $w->print;
        }
        $out .= sprintf "%-35s %-35s", $crisis_text, $war_text;
        $out .="\n";
    }
    $out .= "\n";
    if($self->player_nation ne $nation)
    {
        $out .= "Relations with player: " . $self->diplomacy_exists($self->player_nation, $nation)->print() . "\n";
        $out .= "\n";
    }
    return $out;
}

sub print_borders_analysis
{
    my $self = shift;
    my $nation = shift;
    my @borders = $self->near_nations($nation, 1);

    my $out = "";
    foreach my $b (@borders)
    {
        $out .= as_title("# " . $b  . " #") . "\n";
        my $rel = $self->diplomacy_exists($nation, $b);
        $out .= "  Relations: " . $rel->print_status() . " " . 
                                  $rel->print_crisis_bar() . "\n";
        my $supps = $self->supported($b);
        if($supps)
        {
            $out .= as_subtitle("  Military support in the country:\n");
            my $supporter = $supps->start($b);
            my $sup_rel = $self->diplomacy_exists($nation, $supporter);
            if($sup_rel)
            {
                $out .= "    $supporter (" . $sup_rel->print_status();
                if($sup_rel->is_crisis())
                {
                    $out .= " " . $sup_rel->print_crisis_bar;
                } 
                $out .= ")";
            }
            $out .= "\n";
        }
    }
    return $out;
}
sub print_near_analysis
{
    my $self = shift;
    my $nation = shift;
    my @near = $self->near_nations($nation, 0);
    my $out = "";
    foreach my $b (@near)
    {
        $out .= as_title($b) . " " . $self->diplomacy_exists($nation, $b)->print_status();
        if(! $self->border_exists($nation, $b))
        {
            if($self->exists_military_support($nation, $b))
            {
                $out .= " (supported)\n";
            }
            else
            {
                $out .= "\n";
                my @foreign_borders = $self->get_borders($b);
                foreach my $fb (@foreign_borders)
                {
                    my $other_n = $fb->destination($b);
                    my $sups = $self->supported($other_n);
                    for($sups)
                    {
                        if($sups->start($other_n) eq $nation)
                        {
                            $out .= "    Military support from: $other_n\n";   
                        }
                    }
                }
            }
        }
        else
        {
            $out .= "\n";
        }
    }
    return $out;
}

sub print_hotspots
{
    my $self = shift;
    my $out = "";
    my @crises = $self->get_all_crises();
    $out .= as_title("CRISES") . "\n";
    for(@crises)
    {
        my $c = $_;
        if(! $self->war_exists($c->node1, $c->node2))
        {
            $out .= as_subtitle($c->print_crisis()) . "\n";
            $out .= "    " . $self->diplomacy_exists($self->player_nation, $c->node1)->print() . "\n" if($self->player_nation ne $c->node1);
            $out .= "    " . $self->diplomacy_exists($self->player_nation, $c->node2)->print(). "\n" if($self->player_nation ne $c->node2);
            $out .= "\n";
        }
    }
    $out .= "\n";
    $out .= as_title("WARS") . "\n";
    my @wars = $self->wars->all();
    for(@wars)
    {
        my $w = $_;
        $out .= $w->print() . "\n";
        $out .= "    " . $self->diplomacy_exists($self->player_nation, $w->node1)->print() . "\n" if($self->player_nation ne $w->node1);
        $out .= "    " . $self->diplomacy_exists($self->player_nation, $w->node2)->print(). "\n" if($self->player_nation ne $w->node2);
        $out .= "\n";
    }
    $out .= "\n";
    $out .= as_title("CIVIL WARS") . "\n";
    foreach my $n (@{$self->nation_names})
    {
        if($self->at_civil_war($n))
        {
            $out .= "$n is fighting civil war\n";
            $out .= "    " . $self->diplomacy_exists($self->player_nation, $n)->print() . "\n" if($self->player_nation ne $n);
        }
    }
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
    my $out .= as_title("WAR HISTORY\n\n");
    foreach my $w (@{$self->memorial})
    {
        $out .= $w->print_history;
        $out .= "\n";
    }
    return $out;

}
1;
