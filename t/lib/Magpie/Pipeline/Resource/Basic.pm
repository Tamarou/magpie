package Magpie::Pipeline::Resource::Basic;
use Moose;
use Magpie::Constants;
extends 'Magpie::Resource';

sub GET {
    my $self = shift;
    my $ctxt = shift;
    $self->response->body('GET succeeded!');
    return OK;
}

before 'GET' => sub {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{modified} = 1;
};

1;
