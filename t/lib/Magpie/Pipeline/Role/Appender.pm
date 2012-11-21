package Magpie::Pipeline::Role::Appender;
use Moose::Role;

has reversable => (
    is          => 'rw',
    isa         => 'Str',
    default     => 'UNSET',
);

after 'foo' => sub {
    my $self = shift;
    my $wev = shift;
    my $body = $self->response->body || '';
    $body .= '__' . reverse($self->reversable) . '__';
    $self->response->body($body);
};

1;