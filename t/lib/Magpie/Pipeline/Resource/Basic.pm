package Magpie::Pipeline::Resource::Basic;
use Moose;
extends 'Magpie::Resource';
use Magpie::Constants;
use Data::Dumper::Concise;

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