package Magpie::Pipeline::CurlyArgs;
use Moose;
extends 'Magpie::Component';
use Magpie::Constants;

__PACKAGE__->register_events(
    'foo',
    'baz'
);

has simple_argument => (
    is          => 'rw',
    isa         => 'Str',
    required => 1,
);

sub load_queue {
    return qw( foo );
}

sub foo {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    $body = ref($body) eq 'ARRAY' ? join '', @$body : $body;
    $body .= '_curlyfoo_' . $self->simple_argument;
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