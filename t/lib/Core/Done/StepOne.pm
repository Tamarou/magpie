package Core::Done::StepOne;
use Moose;
use Magpie::Constants;
extends 'Magpie::Component';

__PACKAGE__->register_events(qw(init first));

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
    $ctxt->{content} = '<p>done::StepOne::event_init</p>';
    return DONE;
}

sub first {
    die "Event method called after 'DONE' returned.";
}

1;
