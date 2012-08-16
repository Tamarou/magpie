package Magpie::Resource::Abstract;

# ABSTRACT: INCOMPLETE - Default Resource class.

use Moose;
extends 'Magpie::Resource';
use Magpie::Constants;

sub GET {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->resource($self);
    $self->data( $self->plack_response->body );
    return OK;
}

sub POST {
    my $self = shift;
    my $ctxt = shift;
    $self->parent_handler->resource($self);
    $self->data( $self->plack_response->body );
    return OK;
}

1;
__END__

=pod

# SEALSO: Magpie, Magpie::Resource
