package Magpie::Resource::Session;
use Moose;
extends qw(Magpie::Resource);

use Magpie::Constants;
use Try::Tiny;
use Plack::Session;
use Data::Dumper::Concise;
use Digest::SHA;

has data_source => (
    is      => 'ro',
    isa     => 'KiokuDB',
    lazy    => 1,
    builder => '_build_data_source',
    handles => { lookup_user => 'lookup', }
);

has _kioku_scope => (
    is  => 'rw',
    isa => 'KiokuDB::LiveObjects::Scope',
);

sub _build_data_source {
    my $self = shift;
    my $k    = try {
        $self->resolve_asset( service => 'kioku_dir' );
    }
    catch {
        my $error = "Could not connect to Kioku data source: $_\n";
        warn $error;
        $self->set_error( { status_code => 500, reason => $error } );
    };

    return undef if $self->has_error;
    $self->_kioku_scope( $k->new_scope );
    return $k;
}

has session => (
    isa     => 'Plack::Session',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_sessions'
);

sub _build_sessions { Plack::Session->new( shift->request->env ) }

sub GET {
    my $self    = shift;
    $self->parent_handler->resource($self);
    my $session = $self->session;
    my $id    = $self->get_entity_id;
    unless ( $session->id eq $id ) {
        $self->set_error(
            { status_code => 404, reason => 'Session not found' } );
        return OK;
    }
    $self->data([$session]);
    return OK;
}

sub DELETE {
    my $self    = shift;
    $self->parent_handler->resource($self);    
    my $session = $self->session;
    $session->expire;
    $self->response->redirect( $self->request->base );
    return DONE;
}

sub POST {
    my $self = shift;
    $self->parent_handler->resource($self);    
    my $req  = $self->request;

    my $session  = $self->session;
    my $username = $req->param('username');
    my $password = $req->param('password');

    my $user = try {
        $self->lookup_user("user:${username}");
    }
    catch {
        my $error = "Could not GET data from Kioku data source: $_\n";
        $self->set_error( { status_code => 500, reason => $error } );
    };

    return DECLINED if $self->has_error;

    unless ($user) {
        $self->set_error(
            { status_code => 404, reason => 'User not found' } );
        return DECLINED;
    }

    unless ( $user->check_password($password) ) {
        $self->set_error( { status_code => 403, reason => 'invalid login' } );
        return DECLINED;
    }

    $session->set( user => $user );
    my $id = $session->id;

    my $path = $req->path_info;
    $path =~ s|^/||;
    $path =~ s|/$||;

    $self->state('created');
    $self->response->status(201);
    $self->response->header( 'Location' => $req->base . $path . "/$id" );
    return DONE;
}

1;
__END__
