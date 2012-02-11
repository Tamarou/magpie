package Core::Declined::StepOne;
use Moose;
use Magpie::Constants;
extends 'Magpie::Component';

__PACKAGE__->register_events(qw(init first last));

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
    $ctxt->{content} = '<p>declined::StepOne::event_init</p>';
    return DECLINED;
}

sub first {
    my $self = shift;
    my $ctxt = shift;
    die "Should never run, did not DECLINE\n";
    return OK;
}

sub last {
    my $self = shift;
    my $ctxt = shift;
    die "Should never run, did not DECLINE\n";
    return OK;
}

1;
