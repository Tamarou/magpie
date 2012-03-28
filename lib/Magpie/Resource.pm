package Magpie::Resource;

# ABSTRACT: Abstract base class for all resource types;

use Moose;
extends 'Magpie::Component';
use Magpie::Constants;

__PACKAGE__->register_events( qw(method_not_allowed), HTTP_METHODS );

# XXX: Move to a real Dispactcher
sub load_queue {
    my $self   = shift;
    my $method = $self->plack_request->method;
    if ( scalar grep { $_ eq $method } HTTP_METHODS ) {
        return $method;
    }
    return 'method_not_allowed';
}

has '+_trait_namespace' => ( default => 'Magpie::Plugin::Resource' );

has produces => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'text/plain',
);

has consumes => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'text/plain',
);

has data => (
    is        => 'rw',
    predicate => 'has_data',
    clearer   => 'clear_data',
);

has state => (
    is       => 'rw',
    isa      => 'Str',
    default  => 'uninitialized',
    required => 1,
);

has dependencies => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[HashRef]',
    default => sub { {} },
    handles => {
        add_dependency    => 'set',
        get_dependency    => 'get',
        delete_dependency => 'delete',
        has_dependencies  => 'count',
    },
);

sub methods_implemented {
    my $self = shift;
    my %implemented = ();
    foreach my $class ( $self->meta->linearized_isa ) {
        next if $class =~ /^(Magpie|Moose)::/;
        foreach (HTTP_METHODS){
            $implemented{$_}++ if $class->meta->has_method($_);
        }
    }
    return ( keys( %implemented ));
}

sub method_not_allowed {
    my $self = shift;
    my $method = $self->plack_request->method || 'unknown';
    my @allowed = $self->methods_implemented;
    $self->set_error(
        {   status_code        => 405,
            reason             => "Method '$method' not allowed.",
            additional_headers => [ Allow => \@allowed ],
        }
    );
    return DONE;
}

sub GET {
    shift->method_not_allowed(@_);
}

sub POST {
    shift->method_not_allowed(@_);
}

sub PUT {
    shift->method_not_allowed(@_);
}

sub DELETE {
    shift->method_not_allowed(@_);
}

sub HEAD {
    shift->method_not_allowed(@_);
}

sub OPTIONS {
    shift->method_not_allowed(@_);
}

sub TRACE {
    shift->method_not_allowed(@_);
}

sub PATCH {
    shift->method_not_allowed(@_);
}

sub CONNECT {
    shift->method_not_allowed(@_);
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

