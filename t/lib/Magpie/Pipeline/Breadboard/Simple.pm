package Magpie::Pipeline::Breadboard::Simple;
use Moose;
extends 'Magpie::Transformer';
use Magpie::Constants;
use Bread::Board;

__PACKAGE__->register_events(qw( foo baz ));

sub load_queue {
    return qw( foo baz );
}

sub foo {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    $body .= '_simplefoo_' . '_' . $self->resolve_asset( service => 'somevar' ) . '_';
    $self->response->body( $body );
    return OK;
}

sub baz {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    $body .= '_simplebaz_';
    $self->add_asset( service 'othervar' => 'other value' );
    $self->response->body( $body );
    return OK;
}

1;