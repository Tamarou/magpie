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

sub TRACE {
    shift->set_error('NotImplemented');
    return DONE;
}

sub PATCH {
    shift->set_error('NotImplemented');
    return DONE;
}

sub CONNECT {
    shift->set_error('NotImplemented');
    return DONE;
}

# convenience for container-based Resources
sub get_entity_id {
    my $self = shift;
    my $path = $self->request->path_info;
    return undef if $path =~ /\/$/;
    my @steps = split '/', $path;
    my $id = $self->request->param('id') || pop @steps;
    return $id;
}

1;

__END__

=head1 DESCRIPTION

   A resource is not the thing that is transferred across the wire or picked
   up off the disk or seen from afar while walking your dog. Each of those is
   only a representation. The same is true of physical objects encountered in
   life and never identified with URI and never made accessible on the net.
   Yes, it does present a bit of a quandary, but it is one that we have all
   learned to live with. Our eyes are not powerful enough to see identity
   through the representations, but our minds are powerful enough to associate
   identity to that which we see. Do I think of a different identifier every
   time I see my dog, or do I simply think of my dog as one identity and
   experience many representations of that identity over time (and on into
   memory and imagination)?

   Roy Fielding - July 2002

=head1 SEE ALSO

=for :list
* L<Magpie>

