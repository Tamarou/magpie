package Magpie::Resource::Kioku;
# ABSTRACT: INCOMPLETE - Resource implementation for KiokuDB datastores.

use Moose;
extends 'Magpie::Resource';
use Magpie::Constants;
use Try::Tiny;
use Data::Dumper::Concise;

has data_source => (
    is          => 'ro',
    isa         => 'KiokuX::Model',
    handles     => [qw(directory)],
    lazy_build  => 1,
);

has dsn => (
    isa => "Str",
    is  => "ro",
	predicate => "has_dsn",

);

has extra_args => (
    isa => "HashRef|ArrayRef",
    is  => "ro",
	predicate => "has_extra_args",
);

has typemap => (
    isa => "KiokuDB::TypeMap",
    is  => "ro",
	predicate => "has_typemap",
);

sub _build_data_source {
    my $self = shift;

    my %kioku_args = ();
    foreach my $arg qw(dsn extra_args typemap) {
        my $predicate = 'has_' . $arg;
        $kioku_args{$arg} = $self->$arg if $self->$predicate;
    }

    warn Dumper( \%kioku_args );
    my $source = undef;

    try {
        $source = KiokuX::Model->new(
            %kioku_args,
        ) || die "huh???";
    }
    catch {
        warn "WTF????: $_";
    };
    return $source;
}

sub GET {
    my $self = shift;
    my $req = $self->request;

    my $path = $req->path_info;

    if ( $path =~ /\/$/ ) {
        die "don't know what to do with index request yet";
    }

    my @steps = split '/', $path;

    my $id = $req->param('id') || pop @steps;
    warn "ID $id\n";
    my ($foo) = $self->data_source->lookup( $id );
    warn Dumper( $foo );
    return OK;
}

1;

__END__
=pod

# SEEALSO: Magpie, Magpie::Resource