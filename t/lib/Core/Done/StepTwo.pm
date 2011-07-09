package Core::Done::StepTwo;
use Moose;
use Magpie::Constants;
extends 'Magpie::Component';

__PACKAGE__->register_events(qw(init));

sub load_queue { return ('init') }

sub init {
    die "Event method called after upstream class returned 'DONE'";
}

1;
