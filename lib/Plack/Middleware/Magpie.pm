package Plack::Middleware::Magpie;
use strict;
use warnings;
use parent qw( Plack::Middleware Exporter);
use Plack::Util::Accessor qw(pipeline resource assets context);
our @EXPORT = qw( machine match match_env );
use Scalar::Util qw(reftype);
use Magpie::Machine;
use HTTP::Throwable::Factory;
use Data::Dumper::Concise;

my @STACK = ();

my $_add_frame = sub {
    push @STACK, shift;
};

sub machine (&) {
    my $block = shift;
    $block->();
    return @STACK;
}

sub match {
    my $to_match = shift;
    my $input    = shift;
    warn "IN " . Dumper($to_match, \@_ ) . "--------\n";
    my $match_type   = reftype $to_match || 'STRING';
    my $frame = [$match_type, $to_match, $input];
    $_add_frame->($frame);
}

sub match_env {
    my $to_match = shift;
    my $input    = shift;
    warn "ENVIN " . Dumper($to_match, \@_ ) . "--------\n";
    my $match_type   = reftype $to_match || 'STRING';
    my $frame = [$match_type, $to_match, $input];
    $_add_frame->($frame);
}

sub call {
    my($self, $env) = @_;
    my $app = $self->app;
    warn Dumper($env);

    my @resource_handlers = ();

    my $m = Magpie::Machine->new(
        plack_request => Plack::Request->new($env),
    );

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

    $m->pipeline( @resource_handlers, @{ $pipeline });

    # if we have upstream MW, pass it along
    if ( ref($app) ) {
        my $r = $app->($env);
        $m->plack_response( Plack::Response->new(@$r) );
    }

    $m->run( $self->context || {} );

    if ( $m->has_error ) {
        my $subref = $m->error;
        return $subref->();
    }

    return $m->plack_response->finalize;
};

1;
