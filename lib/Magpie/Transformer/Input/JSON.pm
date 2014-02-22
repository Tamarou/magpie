package Magpie::Transformer::Input::JSON;
use Moose;
extends qw(Magpie::Transformer);
use Magpie::Constants;
use JSON::Any;
use Try::Tiny;

__PACKAGE__->register_events(qw(transform));
sub load_queue { return qw(transform) }

sub transform {
    my $self = shift;
    my $ctxt = shift;
    try {
        $ctxt->{data} = JSON::Any->decode( $self->request->content );
        return OK;
    }
    catch {
        $self->set_error({status_code => 400, reason => $_ });
        return DECLINED
    };
}
