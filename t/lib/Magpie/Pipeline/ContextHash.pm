package Magpie::Pipeline::ContextHash;
use Moose;
extends 'Magpie::Component';
use Magpie::Constants;

__PACKAGE__->register_events(qw(is actually is_frequently));

sub load_queue {
    my ($self, $ctxt) = @_;
    my @bad_idea = sort keys %$ctxt;
    return @bad_idea;
}

sub is {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    $body .= '_is_';
    $self->response->body( $body );
    return OK;
}

sub actually {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    $body .= '_actually_';
    $self->response->body( $body );
    return OK;
}

sub is_frequently {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    $body .= '_is_frequently_';
    $self->response->body( $body );
    return OK;
}

1;