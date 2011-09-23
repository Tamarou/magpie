package Magpie::Transformer;
# ABSTRACT: Magpie Pipeline Transformer Base Class

use Moose;
extends 'Magpie::Component';
use Magpie::Constants;
use Magpie::Resource::Abstract;
# abstract base class for all transformer;
use Data::Dumper::Concise;

has resource => (
    is          => 'rw',
    isa         => 'MagpieResourceObject',
    coerce      => 1,
    default     => sub { return $_[0]->resolve_internal_asset( service => 'default_resource') },
);

# has resource => (
#     is          => 'rw',
#     isa         => 'MagpieResourceObject',
#     coerce      => 1,
#     #default     => { Magpie::Resource::Abstract->new },
# );


#lame
#sub has_resource { defined shift->resource ? 1 : 0 }

# SEEALSO: Magpie

1;
__END__
