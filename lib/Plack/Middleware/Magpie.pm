package Plack::Middleware::Magpie;
use strict;
use warnings;
use parent qw( Plack::Middleware );
use Plack::Util::Accessor qw(pipeline);

use Magpie::Machine;
use HTTP::Throwable::Factory;
use Data::Dumper::Concise;

sub call {
    my($self, $env) = @_;
    my $app = $self->app;

    my $m = Magpie::Machine->new;

    my $pipeline = $self->pipeline;

    $m->pipeline(@{ $pipeline });
    $m->plack_request( Plack::Request->new($env) );

    # if we have upstream MW, pass it along
    if ( ref($app) ) {
        my $r = $app->($env);
        $m->plack_response( Plack::Response->new(@$r) );
    }

    $m->run({});

    if ( $m->has_error ) {
        my $subref = $m->error;
        return $subref->();
    }

    return $m->plack_response->finalize;
};

1;
