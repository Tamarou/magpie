package Magpie::Pipeline::Resource::Kioku::User;
use Moose;

has [qw(name status)] => (
    isa         => 'Str',
    is          => 'ro',
    required    => 1,
);

1;