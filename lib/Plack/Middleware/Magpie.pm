package Plack::Middleware::Magpie;
use parent qw( Plack::Middleware );
use Plack::Util::Accessor qw(pipeline);

use Magpie::Machine;
use HTTP::Throwable::Factory;
use Data::Dumper::Concise;

sub call {
    my($self, $env) = @_;
    my $res = $self->app( $env );

    my $m = Magpie::Machine->new;

    my $pipeline = $self->pipeline;

    $m->pipeline(@{ $pipeline });
    $m->plack_request( Plack::Request->new($env) );
    $m->run({});

    if ( $m->has_error ) {
        my $subref = $m->error;
        return $subref->();
    }

    return $m->plack_response->finalize;
};

1;
