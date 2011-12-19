package Magpie::Resource;
# ABSTRACT: Abstract base class for all resource types;

use Moose;
extends 'Magpie::Component';
use Magpie::Constants;

__PACKAGE__->register_events( qw( GET POST PUT DELETE HEAD OPTIONS ) );

# XXX: Move to a real Dispactcher
sub load_queue {
    my $self = shift;
    my $ctxt = shift;
    return $self->plack_request->method;
}

has '+_trait_namespace' => (
    default => 'Magpie::Plugin::Resource'
);

has produces => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'text/plain',
);

has consumes => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'text/plain',
);

has data => (
    is          => 'rw',
    predicate   => 'has_data',
    clearer     =>  'clear_data',
);

has state => (
    is          => 'rw',
    isa         => 'Str',
    default     => 'uninitialized',
    required    => 1,
);

has dependencies => (
    traits    => ['Hash'],
    is        => 'rw',
    isa       => 'HashRef[HashRef]',
    default   => sub { {} },
    handles   => {
        add_dependency      => 'set',
        get_dependency      => 'get',
        delete_dependency   => 'delete',
        has_dependencies    => 'count',
    },
);

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

sub OPTIONS {
    shift->set_error('NotImplemented');
    return DONE;
}

# convenience for container-based Resources
sub get_entity_id {
    my $self = shift;
    my $path = $self->request->path_info;
    return undef if $path =~ /\/$/;
    my @steps = split '/', $path;
    my $id = $req->param('id') || pop @steps;
    return $id;
}

1;

__END__
=pod

# SEEALSO: Magpie
