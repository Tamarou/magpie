package redirect::StepTwo;
use SAWA::Constants;
use SAWA::Event::Simple;
use XML::LibXML;
our @ISA = qw( SAWA::Event::Simple );

sub registerEvents {
    return qw/ first last /;
}

sub event_init {
    my $self    = shift;
    my $ctxt    = shift;
    $ctxt->{content} .= '<p>redirect::StepTwo::event_init</p>';
    return OK;
}

sub event_first {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= '<p>redirect::StepTwo::event_first</p>';
    return OK;
}

sub event_last {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= '<p>redirect::StepTwo::event_last</p>';
    return OK;
}

1;
