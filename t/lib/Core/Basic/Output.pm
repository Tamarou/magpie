package basic::Output;
use SAWA::Constants;
use SAWA::Output::Scalar;
use vars qw(@ISA);
@ISA = qw(SAWA::Output::Scalar);

sub event_cookie {
    my $self = shift;
    my $ctxt = shift;
    warn "COOKIE IN OUTPUT\n";
    return OK;
}

sub get_content {
    my $self = shift;
    my $ctxt = shift;
    my $out = '<html><body>' . $ctxt->{content} . '</body></html>';
    $self->content($out);
    return OK;
}

1;
