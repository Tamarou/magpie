package Magpie::Resource;
use Moose;
extends 'Magpie::Component';
use Magpie::Constants;
# abstract base class for all resource types;

__PACKAGE__->register_events( qw( GET POST PUT DELETE HEAD ) );

# XXX: Move to a real Dispactcher
sub load_queue {
    my $self = shift;
    my $ctxt = shift;
    return $self->plack_request->method;
}

sub GET {
    shift->set_error('NotImplemented');
    return DONE;
}

sub POST {
    shift->set_error('NotImplemented');
    return DONE;
}

sub PUT {
    shift->set_error('NotImplemented');
    return DONE;
}

sub DELETE {
    shift->set_error('NotImplemented');
    return DONE;
}

sub HEAD {
    shift->set_error('NotImplemented');
    return DONE;
}

1;