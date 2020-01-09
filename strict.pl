#!/usr/bin/env perl
use Mojolicious::Lite;
use Time::Piece;

get '/' => sub {
    my $self       = shift;
    my $today      = localtime;
    my $date_today = $today->datetime( T => " " );
    $self->stash( date_today => $date_today );
    $self->render( template => 'home' );
    return;
};

get 'service' => sub {
    my $self = shift;
    $self->render('service');
    return;
};

get 'case' => sub {
    my $self = shift;
    $self->render('case');
    return;
};

app->start;
