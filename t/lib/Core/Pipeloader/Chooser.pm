package Core::Pipeloader::Chooser;
use Moose;
use Magpie::Constants;
extends 'Magpie::Component';

__PACKAGE__->register_events(qw(init default moe larry curly));

sub load_queue {
    my ($self, $ctxt) = @_;
    my @events = ('init');
    if ( my $event = $self->request->param('appstate') ) {
        push @events, $event;
    }
    else {
        push @events, 'default';
    }
    return @events;
}

sub init {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} = 'chooser::init...';
    return OK;
}

sub default {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= 'chooser::default...';
    $self->parent_handler->add_handler('Core::Pipeloader::Moe');
    return OK;
}

sub moe {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= 'chooser::moe...';
    $self->parent_handler->add_handler('Core::Pipeloader::Moe');
    return OK;
}

sub larry {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= 'chooser::larry...';
    $self->parent_handler->add_handler('Core::Pipeloader::Moe');
    return OK;
}

sub curly {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= 'chooser::curly...';
    $self->parent_handler->add_handlers( qw( Core::Pipeloader::Moe Core::Pipeloader::Larry Core::Pipeloader::Curly Core::Basic::Output) );
    return OK;
}

1;
