package Magpie::Transformer::Input::CGIStruct;
use Moose;
extends qw(Magpie::Transformer);
use Magpie::Constants;
use CGI::Struct;
use Try::Tiny;

__PACKAGE__->register_events(qw(transform));
sub load_queue { return qw(transform) }

sub transform {
    my $self = shift;
    my $ctxt = shift;
    try {
        $ctxt->{data} = build_cgi_struct $self->request->parameters->mixed;
        return OK;
    }
    catch {
        $self->set_error({status_code => 400, reason => $_ });
        return DECLINED
    };
}
