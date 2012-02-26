package Plack::Middleware::TestComponent;
use strict;
use warnings;
use parent qw( Exporter Plack::Middleware);
use Plack::Util::Accessor qw(some_arg);
use Data::Dumper::Concise;

sub call {
    my($self, $env) = @_;
    my $resp = $self->app->($env);
    warn "in mw " . Dumper($resp);
    $resp->[2] .= '__' . $self->some_arg . '__';
    return $resp;
};

# SEEALSO: Magpie, Plack, Plack::Middleware


1;
