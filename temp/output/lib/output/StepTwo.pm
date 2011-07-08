package output::StepTwo;
use SAWA::Constants;
use SAWA::Event::Simple;
use vars qw(@ISA);
@ISA = qw( SAWA::Event::Simple );

sub registerEvents {
    return qw/ /;
}

sub event_init {
    die "Event method called when upstream handler returned 'OUTPUT'"
}

1;
