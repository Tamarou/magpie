package pipeloader::Larry;
use strict;
use warnings;
use SAWA::Constants;
use Data::Dumper;
use SAWA::Event::Simple;
use vars qw(@ISA);
@ISA = qw(SAWA::Event::Simple);

sub registerEvents {
return qw ( moe larry curly);
}

sub event_init {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= 'larry::init...';
    return OK;
}

sub event_default {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->add_handler('basic::Output');
    $ctxt->{content} .= 'larry::default...';
    return OK;
}

sub event_moe {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->add_handler('basic::Output');
    $ctxt->{content} .= 'larry::moe...';
    return OK;
}

sub event_larry {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->add_next_handler('pipeloader::Curly');
    $ctxt->{content} .= 'larry::larry...';
    return OK;
}

sub event_curly {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= 'larry::curly...';
    return OK;
}
1;
