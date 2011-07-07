package Plack::Middleware::Magpie;
use strict;
use warnings;
use parent qw( Plack::Middleware );
use Plack::Util::Accessor qw(pipeline resource assets);

use Magpie::Machine;
use HTTP::Throwable::Factory;
use Data::Dumper::Concise;

sub call {
    my($self, $env) = @_;
    my $app = $self->app;

    my @resource_handlers = ();

    my $m = Magpie::Machine->new;

    my $pipeline = $self->pipeline || [];

    my $resource = $self->resource;

    if ( $resource ) {
        if ( ref( $resource ) eq 'HASH' ) {
            my $class = delete $resource->{class};
            push @resource_handlers, ( $class, $resource );
        }
        else {
            push @resource_handlers, $resource;
        }
    }

    if ( my $assets = $self->assets ) {
        $m->assets( $assets );
    }

    # assume if no resource is given that we want the File data source
#     unless ( scalar @resource_handlers ) {
#         push @resource_handlers, 'Magpie::Resource'
#     }

    $m->pipeline( @resource_handlers, @{ $pipeline });
    $m->plack_request( Plack::Request->new($env) );

    # if we have upstream MW, pass it along
    if ( ref($app) ) {
        warn "upstream";
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
