package Plack::Middleware::Magpie;

# ABSTRACT: Plack Middleware Interface For Pipelined Magpie Applications
use strict;
use warnings;
use parent qw( Exporter Plack::Middleware);

use Plack::Util::Accessor qw(pipeline resource assets context conf accept_matrix config_cache config_assets plugins);

our @EXPORT = qw( machine match match_env match_accept match_template);
use Scalar::Util qw(reftype);
use Magpie::Machine;
use Magpie::Matcher;
use Magpie::Util;
use Magpie::Plugin::URITemplate;
use Magpie::ConfigReader::XML;
use Try::Tiny;
use HTTP::Throwable::Factory;
use File::stat;
#use Data::Dumper::Concise;
my @STACK      = ();
my $MTOKEN     = undef;
my $_add_frame = sub {
    push @STACK, shift;
};

sub make_token {
    return '__MTOKEN__' . int( rand(100000) );
}

sub machine (&) {
    my $block = shift;
    $MTOKEN = make_token();
    $block->();
    return $MTOKEN;
}

sub match {
    my $to_match   = shift;
    my $input      = shift;
    my $match_type = reftype $to_match || 'STRING';
    if ( $match_type eq 'SCALAR' && re::is_regexp($to_match) == 1 ) {
        $match_type = 'REGEXP';
    }
    my $frame = [ $match_type, $to_match, $input, $MTOKEN ];
    $_add_frame->($frame);
}

sub match_env {
    my $to_match   = shift;
    my $input      = shift;
    my $match_type = reftype $to_match || 'STRING';
    if ( $match_type eq 'SCALAR' && re::is_regexp($to_match) == 1 ) {
        $match_type = 'REGEXP';
    }
    my $frame = [ $match_type, $to_match, $input, $MTOKEN ];
    $_add_frame->($frame);
}

sub match_accept {
    my $to_match = shift;
    my $input    = shift;
    my $frame    = [ 'ACCEPT', $to_match, $input, $MTOKEN ];
    $_add_frame->($frame);
}

# NOTE: We do this here (and the config file processor(s)) instead
# of in Matcher.pm so we don't have to reparse the template on every request.
# Consider benchmarking a fork that *does* do it in the Matcher at some point.
sub match_template {
    my $to_match = shift;
    my $input    = shift;
    #warn "IN " . Dumper($input);
    my ($re, $names) = Magpie::Plugin::URITemplate::process_template($to_match);
    my @tuples = Magpie::Util::make_tuples(@{$input});
    my @new_input = ();
    foreach my $pair (@tuples) {
        if (defined $pair->[1]->{traits}) {
            push @{$pair->[1]->{traits}}, '+Magpie::Plugin::URITemplate';            
        }
        else {
            $pair->[1]->{traits} = ['+Magpie::Plugin::URITemplate'];
        }
        
        $pair->[1]->{uri_template} = $to_match;
        push @new_input, @{$pair};
    }
    my $frame    = [ 'REGEXP', $re, \@new_input, $MTOKEN ];
    #warn "NEW FRAME" . Dumper($frame);
    $_add_frame->($frame);
}

sub has_config_cache {
    return defined shift->config_cache;
}

sub call {
    my ( $self, $env ) = @_;

    #warn Dumper( $env );
    my $app = $self->app;

    my @resource_handlers = ();
    my $req = try { Plack::Request->new($env); }
    catch {
        HTTP::Throwable::Factory->throw( 400, { message => $_ } );
    };

    my $pipeline = $self->pipeline || [];

    my $conf_file = $self->conf;
    if ($conf_file) {

        # only XML for now, more options later?
        my $file_meta = stat($conf_file);
        if (   $self->has_config_cache
            && $self->config_cache->{mtime} == $file_meta->mtime )
        {
            my $cache = $self->config_cache;

            # XXX STACK is already global so caching a second time
            # has shitty side effects.
            #my @cached_stack = @{$cache->{match_stack}};
            #unshift @STACK, @cached_stack;

            unshift @{$pipeline}, $cache->{token};
            $self->accept_matrix( $cache->{accept_matrix} );
        }
        else {
            my $reader = Magpie::ConfigReader::XML->new;
            $reader->process($conf_file);

            my $token = $reader->make_token;

            # config-based handlers are added to the front
            # of the stack so there can be a base reusable conf
            # file with dynamic additions in the building class.
            $self->config_cache(
                {

                  #match_stack     => $reader->match_stack, #see the above XXX
                    token         => $token,
                    accept_matrix => $reader->accept_matrix,
                    mtime         => $file_meta->mtime,
                    assets        => $reader->assets,
                }
            );

            unshift @STACK, @{ $reader->match_stack };
            unshift @{$pipeline}, $reader->make_token;
            $self->accept_matrix( $reader->accept_matrix );
            $self->config_assets( $reader->assets );
        }
    }

    my $matcher = Magpie::Matcher->new(
        plack_request    => $req,
        accept_matrix    => $self->accept_matrix || [],
        match_candidates => \@STACK,
    );

    $pipeline = $matcher->detokenize_pipeline($pipeline);

    #warn "pipe " . Dumper( $pipeline, \@STACK );

    my $m = Magpie::Machine->new( plack_request => $req, );

    my $resource = $self->resource;

    if ($resource) {
        if ( ref($resource) eq 'HASH' ) {

            # dont clobber the actual data
            my %copy  = %{$resource};
            my $class = delete $copy{class};
            push @resource_handlers, ( $class, \%copy );
        }
        else {
            push @resource_handlers, $resource;
        }
    }
    elsif ( !grep { !ref($_) && $_->isa('Magpie::Resource') } @{$pipeline} ) {

        # If there is no Resource and nothing in the Pipeline then, really,
        # we haven't found any way to prcess the request. 404 is what most
        # people would expect, I think.
        unless ( scalar @{$pipeline} ) {
            my $err = HTTP::Throwable::Factory->new_exception('NotFound');
            return $err->();
        }
        push @resource_handlers, 'Magpie::Resource::Abstract';
    }

    if ( my $assets = $self->assets ) {
        $m->assets($assets);
    }

    my $config_assets = $self->config_assets || [];
    foreach my $asset ( @{$config_assets} ) {
        #warn "Adding asset" . Dumper($asset);
        $m->add_asset( $asset );
    }

    $m->pipeline( @resource_handlers, @{$pipeline} );

    # if we have upstream MW, pass it along
    if ( ref($app) ) {
        my $r = $app->($env);
        $m->plack_response( Plack::Response->new(@$r) );
    }

    $m->run( $self->context || {} );

    if ( $m->has_error ) {
        my $subref = $m->error();
        return $subref->();
    }

    # XXX: Real Accept-* based serialization will go here eventually.
    #if ($m->resource->has_data) {
    if ( my $data = $m->resource->data ) {

        #my $data = $m->resource->data;
        #warn "got data $data\n";
        my $content_length = length $data || 0;
        if ($content_length) {
            $m->response->content_length($content_length);
            $m->plack_response->body($data);
        }
    }

    return $m->plack_response->finalize;
}

# SEEALSO: Magpie, Plack, Plack::Middleware

1;
