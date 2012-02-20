package Plack::Middleware::TestComponent;
use strict;
use warnings;
use parent qw( Exporter Plack::Middleware);
use Plack::Util::Accessor qw(some_arg);

sub call {
    my($self, $env) = @_;

    my $resp = $self->app($env);
    return $resp;
};

# SEEALSO: Magpie, Plack, Plack::Middleware


1;
