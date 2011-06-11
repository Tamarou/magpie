package Magpie::Pipeline::Resource::Basic;
use Moose;
extends 'Magpie::Resource';
use Magpie::Constants;

sub GET {
    my $self = shift;
    my $ctxt = shift;
    $self->response->body('GET succeeded!');
    return OK;
}

1;