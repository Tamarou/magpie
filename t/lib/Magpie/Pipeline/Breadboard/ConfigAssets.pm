package Magpie::Pipeline::Breadboard::ConfigAssets;
use Moose;
extends 'Magpie::Transformer';
with 'Magpie::Dispatcher::RequestParam';
use Bread::Board;
use Magpie::Constants;

__PACKAGE__->register_events(qw( bareservice simplecontainer blockinjector setterinjector constructorinjector));

sub bareservice {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    $body .= '_configassets_' . '_' . $self->resolve_asset( service => 'somevar' ) . '_';
    $self->response->body( $body );
    return OK;
}

sub simplecontainer {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    $body .= '_simplecontainer_' . '_' . $self->resolve_asset( service => 'MyContainer/somevar' ) . '_';
    $self->response->body( $body );
    return OK;
}

use Data::Dumper::Concise;

sub blockinjector {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    my $simple_moose = $self->resolve_asset( service => 'MyContainer/simple_moose' );
    $body .= '_blockinjector_' . '_' . $simple_moose->name . '_' . $simple_moose->foo . '_' . $simple_moose->favorite_holiday . '_';
    $self->response->body( $body );
    return OK;
}

sub constructorinjector {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    my $simple_moose = $self->resolve_asset( service => 'Container2/simple_moose' );
    $body .= '_constructorinjector_' . '_' . $simple_moose->name . '_' . $simple_moose->foo . '_' . $simple_moose->favorite_holiday . '_';
    $self->response->body( $body );
    return OK;
}

sub setterinjector {
    my ($self, $ctxt) = @_;
    my $body = $self->response->body || '';
    my $simple_moose = $self->resolve_asset( service => 'Container3/simple_moose' );
    $body .= '_setterinjector_' . '_' . $simple_moose->name . '_' . $simple_moose->foo . '_' . $simple_moose->favorite_holiday . '_';
    $self->response->body( $body );
    return OK;
}

1;