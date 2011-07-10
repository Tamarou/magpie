package Core::Output::StepTwo;
use Moose;
use Magpie::Constants;
extends 'Magpie::Component';

__PACKAGE__->register_events(qw(init));

sub load_queue { ('init') }

sub init {
    die "Event method called when upstream handler returned 'OUTPUT'"
}

1;
