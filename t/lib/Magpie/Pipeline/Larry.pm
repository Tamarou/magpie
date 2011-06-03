package Magpie::Pipeline::Larry;
use Moose;
extends 'Magpie::Component';

__PACKAGE__->register_events(
    'foo',
     bar => sub {
        my ($self, $ctxt) = @_;
        my $body = $self->response->body || '';
        $body .= '_larrybar_';
        $self->response->body( $body );
        return 100
     },
    'baz'
);

sub load_queue {
    return qw( foo bar );
}

sub foo {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    warn "LARRY FOO\n";
    $body .= '_larryfoo_';
    $self->response->body( $body );
    return 100;
}

sub baz {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    $body .= '_larrybaz_';
    $self->response->body( $body );
    return 100;
}
1;