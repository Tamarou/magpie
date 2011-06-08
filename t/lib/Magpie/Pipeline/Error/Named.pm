package Magpie::Pipeline::Error::Named;
use Moose;
extends 'Magpie::Component';

__PACKAGE__->register_events(
    'foo', 'bar'
);

sub load_queue {
    return qw( foo bar);
}

sub foo {
    my ($self, $ctxt) = @_;
    $self->set_error('ImATeapot');
    return 100;
}

sub bar {
    my ($self, $ctxt) = @_;
    return 100;
}

1;