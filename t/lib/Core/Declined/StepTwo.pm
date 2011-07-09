package Core::Declined::StepTwo;
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
    $ctxt->{content} .= '<p>declined::StepTwo::event_init</p>';
    return OK;
}


sub first {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= '<p>declined::StepTwo::event_first</p>';
    return OK;
}

sub last {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= '<p>declined::StepTwo::event_last</p>';
    return OK;
}
1;
