package BalanceOfPower::Role::CrisisManager;

use strict;
use Moo::Role;
use Term::ANSIColor;

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw(as_main_title as_html_box as_html_dangerous);

requires 'get_all_crises';
requires 'get_hates';
requires 'crisis_exists';
requires 'war_exists';
requires 'broadcast_event';
requires 'add_crisis';

sub crisis_generator
{
    my $self = shift;
    my @crises = $self->get_all_crises();
    my @hates = ();
    foreach my $h  ($self->get_hates())
    {
        push @hates, $h
            if(! $self->crisis_exists($h->node1, $h->node2))
    }
    my $crises_to_use = \@crises;
    my $hates_to_use = \@hates;
    for(my $i = 0; $i < CRISIS_GENERATION_TRIES; $i++)
    {
        ($hates_to_use, $crises_to_use) = $self->crisis_generator_round($hates_to_use, $crises_to_use);
    }

}

sub crisis_generator_round
{
    my $self = shift;
    my $hates_to_use = shift || [] ;
    my $crises_to_use = shift || [];
    my @hates = $self->shuffle("Crisis generation: choosing hate", @{ $hates_to_use });
    my @crises = $self->shuffle("Crisis generation: choosing crisis", @{ $crises_to_use});
    my @original_hates = @hates;
    my @original_crises = @crises;
                     
    my $picked_hate = undef; 
    my $picked_crisis = undef;
    if(@hates)
    {
        $picked_hate = shift @hates;
    }
    if(@crises)
    {
        $picked_crisis = shift @crises;
    }
   

    my $action = $self->random(0, CRISIS_GENERATOR_NOACTION_TOKENS + 3, "Crisis action choose");
    if($action == 0) #NEW CRISIS
    {
        return (\@original_hates, \@original_crises) if ! $picked_hate; 
        if(! $self->war_exists($picked_hate->node1, $picked_hate->node2))
        {
            $self->create_or_escalate_crisis($picked_hate->node1, $picked_hate->node2);
            return (\@hates, \@original_crises);
        }
    }
    elsif($action == 1) #ESCALATE
    {
        return (\@original_hates, \@original_crises) if ! $picked_crisis; 
        if(! $self->war_exists($picked_crisis->node1, $picked_crisis->node2))
        {
            $self->create_or_escalate_crisis($picked_crisis->node1, $picked_crisis->node2);
        }
        return (\@original_hates, \@crises);
    }
    elsif($action == 2) #COOL DOWN
    {
        return (\@original_hates, \@original_crises) if ! $picked_crisis; 
        if(! $self->war_exists($picked_crisis->node1, $picked_crisis->node2))
        {
            $self->cool_down($picked_crisis->node1, $picked_crisis->node2);
        }
        return (\@original_hates, \@crises);
    }
    elsif($action == 3) #ELIMINATE
    {
        return (\@original_hates, \@original_crises) if ! $picked_crisis; 
        if(! $self->war_exists($picked_crisis->node1, $picked_crisis->node2))
        {
            $self->delete_crisis($picked_crisis->node1, $picked_crisis->node2);
        }
        return (\@original_hates, \@crises);
    }
    else
    {
        return (\@original_hates, \@original_crises);
    }
}
sub create_or_escalate_crisis
{
    my $self = shift;
    my $node1 = shift || "";
    my $node2 = shift || "";
    if(my $crisis = $self->crisis_exists($node1, $node2))
    {
        if(! $crisis->is_max_crisis)
        {
            $crisis->escalate_crisis();
            my $event = "CRISIS BETWEEN $node1 AND $node2 ESCALATES";
            if($crisis->is_max_crisis)
            {
               $event .= " TO MAX LEVEL"; 
            }
            $self->broadcast_event($event, $node1, $node2);
        }
    }
    else
    {
        $self->add_crisis($node1, $node2);
        $self->broadcast_event("CRISIS BETWEEN $node1 AND $node2 STARTED", $node1, $node2);
    }
}
sub cool_down
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    if(my $crisis = $self->crisis_exists($node1, $node2))
    {
        $crisis->cooldown_crisis();
        if(! $crisis->is_crisis())
        {
            my $event = "CRISIS BETWEEN $node1 AND $node2 ENDED";
            $self->broadcast_event($event, $node1, $node2);
        }
        else
        {
            $self->broadcast_event("CRISIS BETWEEN $node1 AND $node2 COOLED DOWN", $node1, $node2);
        }
    }
}
sub print_all_crises
{
    my $self = shift;
    my $n = shift;
    return $self->output_all_crises($n, 'print');
}
sub html_all_crises
{
    my $self = shift;
    my $n = shift;
    return $self->output_all_crises($n, 'html');
}


sub output_all_crises
{
    my $self = shift;
    my $n = shift;
    my $mode = shift;
    my $out;

    $out .= as_main_title("CRISES", $mode);
    my $box = "";
    foreach my $b ($self->get_all_crises())
    {
        if($self->war_exists($b->node1, $b->node2))
        {
            if($mode eq 'print')
            {
                $box .= color("red bold") . $b->print_crisis() . color("reset") . "\n";
            }
            elsif($mode eq 'html')
            {
                $box .= as_html_dangerous($b->html_crisis()) . "<br />";
            }
        }
        else
        {
            if($mode eq 'print')
            {
                $box .= $b->print_crisis() . "\n";
            }
            elsif($mode eq 'html')
            {
                $box .= $b->html_crisis() . "<br />";
            }
            
        }
    }
    if($mode eq 'print')
    {
        return $out . $box;
    }
    elsif($mode eq 'html')
    {
        return $out . as_html_box($box);
    }
}

1;

