package done::StepTwo;
use SAWA::Event::Simple;
our @ISA = qw( SAWA::Event::Simple );

sub registerEvents {
    return qw//;
}

sub event_init {
    die "Event method called after upstream class returned 'DONE'";
}

1;
