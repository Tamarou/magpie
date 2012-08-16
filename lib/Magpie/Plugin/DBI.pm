package Magpie::Plugin::DBI;
use Moose::Role;

# ABSTRACT: A simple Role for dealing with DBI-backed assets;
#
use Magpie::Constants;

has dsn => (
    isa       => "Str",
    is        => "ro",
    predicate => "has_dsn",
);

has extra_args => (
    isa       => "HashRef|ArrayRef",
    is        => "ro",
    predicate => "has_extra_args",
);

has username => (
    is        => 'ro',
    isa       => 'Maybe[Str]',
    predicate => 'has_username',
);

has password => (
    is        => 'ro',
    isa       => 'Maybe[Str]',
    predicate => 'has_password',
);

sub _connect_args {
    my $self = shift;
    my @args = ( $self->dsn || die "dsn is required" );

    if ( $self->has_username ) {
        push @args, user => $self->username;
    }

    if ( $self->has_password ) {
        push @args, password => $self->password;
    }

    if ( $self->has_extra_args ) {
        my $extra = $self->extra_args;

        if ( ref($extra) eq 'ARRAY' ) {
            push @args, @$extra;
        }
        else {
            push @args, %$extra;
        }
    }

    \@args;
}

sub _build_data_source {
    my $self = shift;
    my $k    = undef;

    try {
        $k = $self->resolve_asset( service => 'kioku_dir' );
    }
    catch {
        try {
            $k = KiokuDB->connect( @{ $self->_connect_args } );
        }
        catch {
            my $error = "Could not connect to Kioku data source: $_\n";
            warn $error;
            $self->set_error( { status_code => 500, reason => $error } );
        };
    };

    return undef if $self->has_error;
    $self->_kioku_scope( $k->new_scope );
    return $k;
}


1;
