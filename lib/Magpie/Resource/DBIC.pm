package Magpie::Resource::DBIC;

# ABSTRACT: Resource implementation for DBIx::Class ResultSources.

use Moose;
extends 'Magpie::Resource';
with 'Magpie::Plugin::DBI';
use Class::Load;
use Magpie::Constants;
use Try::Tiny;
use Data::Printer;

has data_source => (
    is         => 'ro',
    isa        => 'DBIx::Class::Schema',
    lazy_build => 1,
);

has result_class => (
    isa      => "Str",
    is       => "ro",
    #required => 1,
);

has schema_class => (
    isa      => "Str",
    is       => "ro",
);

has typemap => (
    isa       => "KiokuDB::TypeMap",
    is        => "ro",
    predicate => "has_typemap",
);


sub _build_data_source {
    my $self = shift;
    my $k    = undef;

    try {
        $k = $self->resolve_asset( service => 'dbic_schema' );
    }
    catch {
        warn "NOPE " . $_;
        try {
            my $schema_class = $self->schema_class;
            $k = $schema_class->connect( @{ $self->_connect_args } );
        }
        catch {
            my $error = "Could not connect to DBIC data source: $_\n";
            warn $error;
            $self->set_error( { status_code => 500, reason => $error } );
        };
    };

    return undef if $self->has_error;
    return $k;
}

sub GET {
    my $self = shift;
    $self->parent_handler->resource($self);
    my $req = $self->request;

    my $path = $req->path_info;
    my $id = $self->get_entity_id;

    if ($path =~ /\/$/  && !$id ) {
        $self->state('prompt');
        return OK;
    }

    my $data = undef;

    try {
        ($data) = $self->data_source->resultset($self->result_class)->find($id);
    }
    catch {
        my $error = "Could not GET data from DBIC data source: $_\n";
        $self->set_error( { status_code => 500, reason => $error } );
    };

    return OK if $self->has_error;

    unless ($data) {
        $self->set_error({ status_code => 404, reason => 'Resource not found.'});
        return OK;
    }

    #warn "got data " . p($data);

    $self->data($data);
    return OK;
}

sub POST {
    my $self = shift;
    my $req = $self->request;

    my $to_store = undef;

    my $result_class = $self->result_class;

    # XXX should check for a content body first.
    my $args = {};

    if ( $self->has_data ) {
        $args = $self->data;
        #warn "HAS DATA " . p($args);
        $self->clear_data;
    }
    else {
        for ( $req->param ) {
            $args->{$_} = $req->param($_);
        }
    }

    # permit POST to update if there's an entity ID.
    # XXX: Should this go in an optional Role?
    if (my $existing_id = $self->get_entity_id) {
        my $existing = undef;
        try {
            ($existing) = $self->data_source->resultset($result_class)->find($existing_id);
        }
        catch {
            my $error = "Could not fetch data from DBIC data source for POST editing with entity with ID '$existing_id': $_\n";
            $self->set_error( { status_code => 500, reason => $error } );
        };

        return OK if $self->has_error;

        if ($existing) {
            foreach my $key (keys(%{$args})) {
                $existing->$key( $args->{$key} );
            }

            try {
               $existing->update;
            }
            catch {
                my $error = "Error updating data entity with ID $existing_id: $_\n";
                $self->set_error( { status_code => 500, reason => $error } );
            };

            return OK if $self->has_error;

            # finally, if it all went OK, say so.
            $self->state('updated');
            $self->response->status(204);
            return OK;
        }
    }

    # if we make it here there is no existing record, so make a new one.
    my $id = undef;

    try {
        $to_store = $self->data_source->resultset($result_class)->create($args);
        $id = $to_store->id;
    }
    catch {
        my $error = "Could not store POST data in DBIC data source: $_\n";
        warn $error;
        $self->set_error( { status_code => 500, reason => $error } );
    };

    return DECLINED if $self->has_error;

    # XXX: all of this needs to go in an abstract object downstream serializer
    # can figure stuff out
    my $path = $req->path_info;
    $path =~ s|^/||;
    $path =~ s|/$||;
    $self->state('created');
    $self->response->status(201);
    $self->response->header( 'Location' => $req->base . $path . "/$id" );
    return OK;
}

sub DELETE {
    my $self = shift;
    $self->parent_handler->resource( $self );
    my $req = $self->request;

    my $ds = $self->data_source;
    my $id = $self->get_entity_id;
    my $existing = undef;

    unless ($id) {
        my $error = "DELETE request requires and entity ID.\n";
        $self->set_error({ status_code => 500, reason => $error });
    }

    try {
        ($existing) = $ds->resultset($self->result_class)->find($id);
    };

    unless ($existing) {
        my $error = "Resource not found for ID '$id'.\n";
        $self->set_error({ status_code => 404, reason => $error });
    }


    try {
        $existing->delete;
    }
    catch {
        my $error = "Could not delete data from DBIC data source: $_\n";
        $self->set_error({ status_code => 500, reason => $error });
    };

    return OK if $self->has_error;
    $self->state('deleted');
    $self->response->status(204);
    return OK;
}

before [HTTP_METHODS] => sub {
	my $self = shift;
	$self->parent_handler->resource($self);
};

sub PUT {
    my $self = shift;
    my $req = $self->request;
    my $schema = $self->data_source;
    my $to_store = undef;

    my $wrapper_class = $self->wrapper_class;

    # XXX should check for a content body first.
    my %args = ();

    if ( $self->has_data ) {
        %args = %{ $self->data };
        $self->clear_data;
    }
    else {
        for ( $req->param ) {
            $args{$_} = $req->param($_);
        }
    }

    my $existing_id = $self->get_entity_id;

    unless ($existing_id) {
        $self->set_error({
            status_code => 400,
            reason => "Attempt to PUT without a definable entity ID."
        });
        return DONE;
    }


    my $existing = undef;
    try {
        $existing = $schema->resultset($self->result_class)->find($existing_id);
    }
    catch {
        my $error = "Could not fetch data from DBIC data source for PUT editing if entity with ID $existing_id: $_\n";
        $self->set_error( { status_code => 500, reason => $error } );
    };

    return OK if $self->has_error;

    unless ($existing) {
        $self->set_error(404);
        return DONE;
    }

    my $existing_obj = $existing->as_obj;
    foreach my $key (keys(%args)) {
        try {
            $existing_obj->$key( $args{$key} );
        }
        catch {
            my $error = "Error updating property '$key' of Resource ID $existing_id: $_\n";
            $self->set_error( { status_code => 500, reason => $error } );
            last;
        };
    }


    return OK if $self->has_error;

    try {
        $self->data_source->txn_do(sub {
            $existing->update($existing_obj->to_storage);
        });
    }
    catch {
        my $error = "Error updating data entity with ID $existing_id: $_\n";
        $self->set_error( { status_code => 500, reason => $error } );
    };

    return OK if $self->has_error;

    # finally, if it all went OK, say so.
    $self->state('updated');
    $self->response->status(204);
    return OK;
}

1;

# package MagpieGenericWrapper;
#
# sub new {
#     my $proto = shift;
#     my %args  = @_;
#     return bless \%args, $proto;
# }

1;

__END__

=pod

# SEEALSO: Magpie, Magpie::Resource
