package declined::StepOne;
use SAWA::Constants;
use SAWA::Machine;
use SAWA::Event::Simple;
use vars qw( @ISA );
@ISA = qw( SAWA::Event::Simple );

sub registerEvents {
    return qw/ first last /;
}

sub event_init {
    my $self    = shift;
    my $ctxt    = shift;
    $ctxt->{content} = '<p>declined::StepOne::event_init</p>';  
    return DECLINED;
}

sub event_first {
    my $self = shift;
    my $ctxt = shift;
    die "Should never run, did not DECLINE\n";
    return OK;
}

sub event_last {
    my $self = shift;
    my $ctxt = shift;
    die "Should never run, did not DECLINE\n";
    return OK;
}

1;
