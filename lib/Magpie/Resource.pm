package Magpie::Resource;
use Moose;
extends 'Magpie::Component';
use Magpie::Constants;
# abstract base class for all resource types;

__PACKAGE__->register_events( qw( GET POST PUT DELETE HEAD ) );

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