package Magpie::Transformer;
# ABSTRACT: Magpie Pipeline Transformer Base Class

use Moose;
extends 'Magpie::Component';
use Magpie::Constants;
use Magpie::Resource::File;
# abstract base class for all transformer;
use Data::Dumper::Concise;

has resource => (
    is          => 'rw',
    isa         => 'MagpieResourceObject|Undef',
    coerce      => 1,
);

#lame
sub has_resource { defined shift->resource ? 1 : 0 }

# SEEALSO: Magpie

1;
__END__
