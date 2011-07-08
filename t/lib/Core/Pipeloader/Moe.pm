package Core::Pipeloader::Moe;
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
    $ctxt->{content} .= 'moe::init...';
    return OK;
}

sub default {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->add_handler('Core::Basic::Output');
    $ctxt->{content} .= 'moe::default...';
    return OK;
}

sub moe {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->add_handler('Core::Pipeloader::Larry');
    $ctxt->{content} .= 'moe::moe...';
    return OK;
}

sub larry {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->add_handlers(qw( Core::Pipeloader::Larry Core::Basic::Output ));
    $ctxt->{content} .= 'moe::larry...';
    return OK;
}

sub curly {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->reset_handlers(qw( Core::Basic::Output ));
    $ctxt->{content} .= 'moe::curly...';
    return OK;
}

1;
