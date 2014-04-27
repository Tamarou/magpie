package Magpie::Pipeline::Resource::Kioku::User;
use Moose;

has [qw(name status)] => (
    isa         => 'Str',
    is          => 'ro',
    required    => 1,
);

sub TO_JSON {
    my $self = shift;
    return {
        name => $self->name,
        status => $self->status,
    };
}

1;