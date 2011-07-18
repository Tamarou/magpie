package Magpie::Pipeline::Larry;
use Moose;
extends 'Magpie::Component';
use Magpie::Constants;

__PACKAGE__->register_events(
    'foo',
     bar => sub {
        my ($self, $ctxt) = @_;
        my $body = $self->response->body || '';
        $body .= '_larrybar_';
        $self->response->body( $body );
        return OK;
     },
    'baz'
);

sub load_queue {
    return qw( foo bar );
}

sub foo {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    $body .= '_larryfoo_';
    $self->response->body( $body );
    return OK;
}

sub baz {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    $body .= '_larrybaz_';
    $self->response->body( $body );
    return OK;
}
1;