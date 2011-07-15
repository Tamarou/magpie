package Plack::Middleware::Magpie;
use strict;
use warnings;
use parent qw( Exporter Plack::Middleware);
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
    return '__PLACEHOLDER__';
}

sub match {
    my $to_match = shift;
    my $input    = shift;
    my $match_type   = reftype $to_match || 'STRING';
    my $frame = [$match_type, $to_match, $input];
    $_add_frame->($frame);
}

sub match_env {
    my $to_match = shift;
    my $input    = shift;
    my $match_type   = reftype $to_match || 'STRING';
    my $frame = [$match_type, $to_match, $input];
    $_add_frame->($frame);
}

sub build_machine {
    my $req = shift;
    my $env = $req->env;
    my $path = $req->path_info;
    my @out = ();
    foreach my $frame (@STACK) {
        #warn "frame " . Dumper($frame);
        my $match_type = $frame->[0];
        if ($match_type eq 'STRING') {
            push @out, @{$frame->[2]} if $frame->[1] eq $path;
        }
        elsif ($match_type eq 'REGEXP') {
            push @out, @{$frame->[2]} if $frame->[1] =~ $path;
        }
        elsif ($match_type eq 'CODE') {
            my $temp = $frame->[1]->($env);
            push @out, @{$temp};
        }
        elsif ($match_type eq 'HASH') {
            my $rules = $frame->[1];
            my $matched = 0;
            foreach my $k (keys %{$rules} ) {
                last unless defined $env->{$k};
                my $val = $rules->{$k};
                if (reftype $val eq 'REGEXP') {
                    $matched++ if $env->{$k} =~ $val;
                }
                else {
                    $matched++ if qq($env->{$k}) eq qq($val);
                }
            }
            push @out, @{$frame->[2]} if $matched == scalar keys %{$rules};
        }
        else {
            warn "I don't know how to match '$match_type', skipping.\n"
        }
    }
    return \@out;
}

sub call {
    my($self, $env) = @_;
    my $app = $self->app;

    my @resource_handlers = ();
    my $req = Plack::Request->new($env);
    my $dynamic = build_machine($req) || [];
    my $pipeline = $self->pipeline    || [];

    # XXX HACK ALERT: this going to have to get much smarter.
    if ( grep { /__PLACEHOLDER__/ } @$pipeline ) {
        my @temp = ();
        foreach ( @{$pipeline} ) {
            if ($_ eq '__PLACEHOLDER__') {
                push @temp, @{$dynamic};
            }
            else {
                push @temp, $_;
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

1;
