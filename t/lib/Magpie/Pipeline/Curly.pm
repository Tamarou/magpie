package Magpie::Pipeline::Curly;
use Moose;
extends 'Magpie::Component';
use Magpie::Constants;

__PACKAGE__->register_events(
    'foo',
     bar => sub {
        my ($self, $ctxt) = @_;
        my $body = $self->response->body || '';
        $body .= '_curlybar_';
        $self->response->body( $body );
        return OK;
     },
    'baz'
);

sub load_queue {
    return qw( foo );
}

sub foo {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    $body .= '_curlyfoo_';
    $self->response->body( $body );
    return OK;
}

sub baz {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    $body .= '_curlybaz_';
    $self->response->body( $body );
    return OK;
}
1;