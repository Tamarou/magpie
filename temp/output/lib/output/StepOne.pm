package output::StepOne;
use SAWA::Constants;
use SAWA::Event::Simple;
our @ISA = qw( SAWA::Event::Simple );

sub registerEvents {
    return qw/ first /;
}

sub event_init {
    my $self    = shift;
    my $ctxt    = shift;
    $ctxt->{content} = '<p>output::StepOne::event_init</p>';
    return OUTPUT;
}

sub event_first {
    die "Event method called after event_init returned 'OUTPUT'";
}

1;
