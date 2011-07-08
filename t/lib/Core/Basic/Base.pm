package basic::Base;
use SAWA::Constants;
use SAWA::Event::Simple;
use vars qw(@ISA);
@ISA = qw( SAWA::Event::Simple );

sub registerEvents {
    return qw/ first last /;
}

sub event_init {
    my $self    = shift;
    my $ctxt    = shift;
    $ctxt->{content} = '<p>basic::Base::event_init</p>';
    return OK;
}

sub event_first {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= '<p>basic::Base::event_first</p>';
    return OK;
}

sub event_last {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= '<p>basic::Base::event_last</p>';
    return OK;
}

1;
