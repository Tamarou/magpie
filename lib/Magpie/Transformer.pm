package Magpie::Transformer;
# ABSTRACT: Magpie Pipeline Transformer Base Class

use Moose;
extends 'Magpie::Component';
use Magpie::Constants;

# abstract base class for all transformer;
use Data::Dumper::Concise;

has '+_trait_namespace' => (
    default => 'Magpie::Plugin::Transformer'
);

has resource => (
    is          => 'rw',
    isa         => 'MagpieResourceObject',
    coerce      => 1,
    default     => sub { return $_[0]->resolve_internal_asset( service => 'default_resource') },
);

# SEEALSO: Magpie

1;
__END__
