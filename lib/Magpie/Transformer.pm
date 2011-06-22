package Magpie::Transformer;
use Moose;
extends 'Magpie::Component';
use Magpie::Constants;
use Magpie::Resource::File;
# abstract base class for all transformer;
use Data::Dumper::Concise;

has resource => (
    is          => 'rw',
    isa         => 'MagpieResourceObject',
    coerce      => 1,
    default     => sub { Magpie::Resource::File->new },
    predicate   => 'has_resource',
);

1;
__END__