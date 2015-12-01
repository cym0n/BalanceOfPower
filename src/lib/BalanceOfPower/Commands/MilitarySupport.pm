package BalanceOfPower::Commands::MilitarySupport;

use Moo;

extends 'BalanceOfPower::Commands::TargetNation';

sub get_available_targets
{
    my $self = shift;
    my $player = $self->actor;
    return grep { $self->world->get_nation($_)->accept_military_support($player, $self->world) } $self->world->get_friends($player);
}

sub IA
{
    my $self = shift;
    my $actor = $self->get_nation();

    my @crises = $self->world->get_crises($actor->name);
    my @friends = $self->world->shuffle("Choosing friend to support for " . $actor->name, $self->world->get_friends($actor->name));
    if(@crises > 0)
    {
        foreach my $c ($self->world->shuffle("Mixing crisis for war for " . $actor->name, @crises))
        {
            my $enemy = $self->world->get_nation($c->destination($actor->name));
            next if $self->world->war_busy($enemy->name);
            for(@friends)
            {
                if($self->world->border_exists($_, $enemy->name))
                {
                    return "MILITARY SUPPORT " . $_;
                }
            }
        }
    }
    if(@friends)
    {
        my $f = $friends[0];
        if($self->world->get_nation($f)->accept_military_support($actor->name, $self->world))
        {
            return "MILITARY SUPPORT " . $f;
        }
    }
    return undef;
}

1;
