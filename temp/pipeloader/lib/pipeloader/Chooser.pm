package pipeloader::Chooser;
use strict;
use warnings;
use SAWA::Constants;
use Data::Dumper;
use SAWA::Event::Simple;
use vars qw(@ISA);
@ISA = qw(SAWA::Event::Simple);

sub registerEvents {
return qw ( larry moe curly );
}

sub event_init {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} = 'chooser::init...';
    return OK;
}

sub event_default {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= 'chooser::default...';
    $self->parent_handler->add_handler('pipeloader::Moe');
    return OK;
}

sub event_moe {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= 'chooser::moe...';
    $self->parent_handler->add_handler('pipeloader::Moe');
    return OK;
}

sub event_larry {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= 'chooser::larry...';
    $self->parent_handler->add_handler('pipeloader::Moe');
    return OK;
}

sub event_curly {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= 'chooser::curly...';
    $self->parent_handler->add_handlers( qw( pipeloader::Moe pipeloader::Larry pipeloader::Curly basic::Output) );
    return OK;
}

1;
