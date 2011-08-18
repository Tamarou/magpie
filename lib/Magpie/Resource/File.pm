package Magpie::Resource::File;
# ABSTRACT: INCOMPLETE - Basic file Resource implementation.

use Moose;
extends 'Magpie::Resource';
use Magpie::Constants;
use Data::Dumper::Concise;
use Plack::App::File;

has root => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_root',
);

sub GET {
    my $self = shift;
    my $ctxt = shift;
    my %paf_args = ();

    $paf_args{root} = $self->root if $self->has_root;
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
    $self->plack_response( Plack::Response->new(@$r) );

    return OK;
}

1;

__END__
=pod

# SEALSO: Magpie, Magpie::Resource
