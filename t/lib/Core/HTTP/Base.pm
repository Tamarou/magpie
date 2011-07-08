package Core::HTTP::Base;
use Moose;
use Magpie::Constants;
extends 'Magpie::Component';

__PACKAGE__->register_events(qw(init cookie headers multicookie redirect redirect_cookie));

sub load_queue {
    my ($self, $ctxt) = @_;
    my @events = ('init');
    if ( my $event = $self->request->param('appstate') ) {
        push @events, $event;
    }
    return @events;
}

sub init {
    my $self    = shift;
    my $ctxt    = shift;
    $ctxt->{content} = '<html><body><p>Howdy</p></body></html>';
    return OK;
}

sub event_cookie {
    my $self = shift;
    my $ctxt = shift;
    $self->cookie( -name =>'name',  -value => 'val' );
    return OK;
}

sub event_multicookie {
    my $self = shift;
    my $ctxt = shift;
    $self->cookie( -name =>'name1',  -value => 'oreo' );
    $self->cookie( -name =>'name2',  -value => 'peanutbutter' );
    return OK;
}

sub event_headers {
    my $self = shift;
    my $ctxt = shift;
    $self->mime_type('text/xml');
    $self->charset('UTF-8');
    $self->header( 'X-Wibble' => 'text/x-ubu' );
    $self->header( Bogus => 'arbitrary' );
    return OK;
}

sub event_redirect {
    my $self = shift;
    my $ctxt = shift;
    $self->redirect('/imnotthere');
    return OK;
}

sub event_redirect_cookie {
    my $self = shift;
    my $ctxt = shift;
    $self->cookie( -name =>'name',  -value => 'val' );
    $self->redirect('/imnotthere');
    return OK;
}


1;
