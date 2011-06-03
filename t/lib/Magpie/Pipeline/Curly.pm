package Magpie::Pipeline::Curly;
use Moose;
extends 'Magpie::Component';

__PACKAGE__->register_events(
    'foo',
     bar => sub {
        my ($self, $ctxt) = @_;
        my $body = $self->response->body || '';
        $body .= '_curlybar_';
        $self->response->body( $body );
        return 100
     },
    'baz'
);

sub load_queue {
    return qw( foo );
}

sub foo {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    warn "CURLY FOO\n";
    $body .= '_curlyfoo_';
    $self->response->body( $body );
    return 100;
}

sub baz {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    $body .= '_curlybaz_';
    $self->response->body( $body );
    return 100;
}
1;