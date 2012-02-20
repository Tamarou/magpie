package Magpie::Transformer::TT2;
# ABSTRACT: Use Plack Middleware Handlers As Pipeline Components

use Moose;
extends 'Magpie::Transformer';
use Magpie::Constants;
use Try::Tiny;
#use Data::Dumper::Concise;

__PACKAGE__->register_events( (qw(call_middleware)));

sub load_queue { return (qw( call_middleware )) }

has middleware_sub => (
    is          => 'rw',
    isa         => 'CodeRef',
    required    => 1,
);

sub call_middleware {
    my ($self, $ctxt) = @_;
    my $tt = $self->transformer;
	warn "MW CALLED";
    return OK;
}

# SEEALSO: Magpie

1;