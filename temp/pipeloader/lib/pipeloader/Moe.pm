package pipeloader::Moe;
use strict;
use warnings;
use SAWA::Constants;
use Data::Dumper;
use SAWA::Event::Simple;
use vars qw(@ISA);
@ISA = qw(SAWA::Event::Simple);

sub registerEvents {
return qw ( moe larry curly );
}

sub event_init {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= 'moe::init...';
    return OK;
}

sub event_default {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->add_handler('basic::Output');
    $ctxt->{content} .= 'moe::default...';
    return OK;
}

sub event_moe {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->add_handler('pipeloader::Larry');
    $ctxt->{content} .= 'moe::moe...';
    return OK;
}

sub event_larry {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->add_handlers(qw( pipeloader::Larry basic::Output ));
    $ctxt->{content} .= 'moe::larry...';
    return OK;
}

sub event_curly {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->reset_handlers(qw( basic::Output ));
    $ctxt->{content} .= 'moe::curly...';
    return OK;
}

1;
