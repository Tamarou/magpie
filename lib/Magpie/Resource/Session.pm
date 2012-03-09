package Magpie::Resource::Session;
use Moose;
extends qw(Magpie::Resource);

use Magpie::Constants;
use Try::Tiny;
use Plack::Session;

# make this an abstract base class
sub lookup_user { confess 'You need to implement a lookup user method' } 

has session => (
    isa     => 'Plack::Session',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_session'
);

sub _build_session { Plack::Session->new( shift->request->env ) }

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
        my $error = "Could not lookup user: $_\n";
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
