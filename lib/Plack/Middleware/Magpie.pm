package Plack::Middleware::Magpie;
# ABSTRACT: Plack Middleware Interface For Pipelined Magpie Applications
use strict;
use warnings;
use parent qw( Exporter Plack::Middleware);
use Plack::Util::Accessor qw(pipeline resource assets context conf);
our @EXPORT = qw( machine match match_env );
use Scalar::Util qw(reftype);
use Magpie::Machine;
use HTTP::Throwable::Factory;
use Magpie::ConfigReader::XML;
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

sub build_machine {
    my $req = shift;

    my $env = $req->env;
    my $path = $req->path_info;
    my $out = {};

    foreach my $frame (@STACK) {
        #warn "frame " . Dumper($frame);
        my $match_type = $frame->[0];
        my $token = $frame->[3];
        $out->{$token} ||= [];
        if ($match_type eq 'STRING') {
            push @{$out->{$token}}, @{$frame->[2]} if $frame->[1] eq $path;
        }
        elsif ($match_type eq 'REGEXP') {
            push @{$out->{$token}}, @{$frame->[2]} if  $path =~ /$frame->[1]/;
        }
        elsif ($match_type eq 'CODE') {
            my $temp = $frame->[1]->($env);
            push @{$out->{$token}}, @{$temp};
        }
        elsif ($match_type eq 'HASH') {
            my $rules = $frame->[1];
            my $matched = 0;
            foreach my $k (keys %{$rules} ) {
                last unless defined $env->{$k};
                my $val = $rules->{$k};
                my $val_type = reftype $val;
                if ($val_type and $val_type eq 'REGEXP') {
                    $matched++ if $env->{$k} =~ m/$val/;
                }
                else {
                    $matched++ if qq($env->{$k}) eq qq($val);
                }
            }
            push @{$out->{$token}}, @{$frame->[2]} if $matched == scalar keys %{$rules};
        }
        elsif ($match_type eq 'AUTO') {
            push @{$out->{$token}}, @{$frame->[2]};
        }
        else {
            warn "I don't know how to match '$match_type', skipping.\n"
        }
    }
    return $out;
}

sub call {
    my($self, $env) = @_;
    my $app = $self->app;

    my @resource_handlers = ();
    my $req         = Plack::Request->new($env);
    my $pipeline    = $self->pipeline     || [];

    my $conf_file = $self->conf;
    if ($conf_file) {
        my $reader = Magpie::ConfigReader::XML->new;
        @STACK = $reader->process($conf_file);
        push @{$pipeline}, $reader->make_token;

    }

    my $machine_map = build_machine($req) || {};
    my @tokens      = keys( %{$machine_map} );

    #warn Dumper($machine_map);
    if ( scalar @tokens ) {
        my @temp = ();
        foreach my $step ( @{$pipeline} ) {
            if ( grep { $_ eq $step } @tokens ) {
                push @temp, @{$machine_map->{$step}};
            }
            else {
                push @temp, $step;
            }
        }
        $pipeline = \@temp;
    }

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
