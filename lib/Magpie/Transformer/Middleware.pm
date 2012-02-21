package Magpie::Transformer::Middleware;
# ABSTRACT: Use Plack Middleware Handlers As Pipeline Components

use Moose;
extends 'Magpie::Transformer';
use Magpie::Constants;
use Try::Tiny;
use Plack::Response;
use Plack::Request;

use Data::Dumper::Concise;

__PACKAGE__->register_events( (qw(call_middleware)));

sub load_queue { return (qw( call_middleware )) }

has middleware_sub => (
    is          => 'rw',
    isa         => 'CodeRef',
    required    => 1,
);

sub call_middleware {
    my ($self, $ctxt) = @_;
	warn "MW CALLED";
	my $env = $self->request->env;
	my $mw = $self->middleware_sub->($env);
	my $r = $mw->($env);
	warn "RRRRRRRR" . Dumper($r);
	my $new_resp = Plack::Response->new(@$r);
	$self->plack_response( $new_resp );
	$self->plack_request( Plack::Request->new($new_resp->env) );
    return OK;
}

# SEEALSO: Magpie

1;