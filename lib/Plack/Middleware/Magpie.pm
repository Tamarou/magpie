package Plack::Middleware::Magpie;
# ABSTRACT: Plack Middleware Interface For Pipelined Magpie Applications
use strict;
use warnings;
use parent qw( Exporter Plack::Middleware);
use Plack::Util::Accessor qw(pipeline resource assets context conf accept_matrix);
our @EXPORT = qw( machine match match_env match_accept);
use Scalar::Util qw(reftype);
use Magpie::Machine;
use Magpie::Matcher;
use Magpie::ConfigReader::XML;
use HTTP::Throwable::Factory;
use Data::Dumper::Concise;

my @STACK = ();
my $MTOKEN = undef;
my $_add_frame = sub {
    push @STACK, shift;
};

sub make_token {
    return '__MTOKEN__' . int(rand(100000));
}

sub machine (&) {
    my $block = shift;
    $MTOKEN = make_token();
    $block->();
    return $MTOKEN;
}

sub match {
    my $to_match = shift;
    my $input    = shift;
    my $match_type   = reftype $to_match || 'STRING';
    my $frame = [$match_type, $to_match, $input, $MTOKEN];
    $_add_frame->($frame);
}

sub match_env {
    my $to_match = shift;
    my $input    = shift;
    my $match_type   = reftype $to_match || 'STRING';
    my $frame = [$match_type, $to_match, $input, $MTOKEN];
    $_add_frame->($frame);
}

sub match_accept {
    my $to_match = shift;
    my $input    = shift;
    my $frame = ['ACCEPT', $to_match, $input, $MTOKEN];
    $_add_frame->($frame);
}

sub call {
    my($self, $env) = @_;
    my $app = $self->app;

    my @resource_handlers = ();
    my $req         = Plack::Request->new($env);
    my $pipeline    = $self->pipeline     || [];

    my $conf_file = $self->conf;
    if ($conf_file) {
        # only XML for now, more options later?
        my $reader = Magpie::ConfigReader::XML->new;
        $reader->process($conf_file);

        # config-based handlers are added to the front
        # of the stack so there can be a base reusable conf
        # file with dynamic additions in the building class.
        unshift @STACK, @{ $reader->match_stack };
        unshift @{$pipeline}, $reader->make_token;

    }

    my $matcher = Magpie::Matcher->new(
        plack_request       => $req,
        accept_matrix       => $self->accept_matrix || [],
        match_candidates    => \@STACK,
    );

    $pipeline = $matcher->detokenize_pipeline($pipeline);
    #warn "pipe " . Dumper( $pipeline );

    my $m = Magpie::Machine->new(
        plack_request => $req,
    );

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

# SEEALSO: Magpie, Plack, Plack::Middleware


1;
