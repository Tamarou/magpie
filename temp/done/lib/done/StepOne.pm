package done::StepOne;
use SAWA::Constants;
use SAWA::Event::Simple;
use vars qw( @ISA );
@ISA = qw( SAWA::Event::Simple );

sub registerEvents {
    return qw/ first /;
}

sub event_init {
    my $self    = shift;
    my $ctxt    = shift;
    $ctxt->{content} = '<p>done::StepOne::event_init</p>';
    return DONE;
}

sub event_first {
    die "Event method called after 'DONE' returned.";
}

1;
