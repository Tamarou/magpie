package Magpie::Resource::File;
# ABSTRACT: INCOMPLETE - Basic file Resource implementation.

use Moose;
extends 'Magpie::Resource';
use Magpie::Constants;
use Data::Dumper::Concise;
use Plack::App::File;

has root => (
    traits => [ qw(MooseX::UndefTolerant::Attribute)],
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_root',
);

sub GET {
    my $self = shift;
    my $ctxt = shift;
    my %paf_args = ();

    if ( $self->has_root ) {
        $paf_args{root} = $self->root;
    }
    elsif ( defined $self->request->env->{DOCUMENT_ROOT} ) {
        $paf_args{root} = $self->request->env->{DOCUMENT_ROOT};
        $self->root($self->request->env->{DOCUMENT_ROOT});
    }

    my $paf = Plack::App::File->new(%paf_args);
    my $r = $paf->call($self->request->env);

    unless ( $r->[0] == 200 ) {
        $self->set_error({
            status_code => $r->[0],
            additional_headers => $r->[1],
            reason => join "\n", @{$r->[2]},
        });
    }
    $self->parent_handler->resource($self);
    $self->data( $r->[2] );

    return OK;
}

1;

__END__
=pod

# SEALSO: Magpie, Magpie::Resource
