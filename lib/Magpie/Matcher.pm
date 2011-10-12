package Magpie::Matcher;
#ABSTRACT: Multi-purpose Dispatcher Magic

use Moose;
use Scalar::Util qw(reftype);
use HTTP::Negotiate;
use Data::Dumper::Concise;

has plack_request => (
    is          => 'ro',
    isa         => 'Plack::Request',
    required    => 1,
);

has match_candidates => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[ArrayRef]',
    default => sub { [] },
    handles => {
        add_candidates => 'push',
    },
);

has accept_matrix => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[ArrayRef]',
    default => sub { [] },
);

sub make_map {
    my $self = shift;

    my $candidates = $self->match_candidates;

    my $req = $self->plack_request;

    my $env = $req->env;
    my $path = $req->path_info;
    my $out = {};

    # this is expensive, so only do it once
    my $accept_variant = HTTP::Negotiate::choose($self->accept_matrix, $req->headers);

    foreach my $frame (@{ $candidates }) {
        #warn "frame " . Dumper($frame);
        my $match_type = $frame->[0];
        my $token = $frame->[3] || '__default__';
        $out->{$token} ||= [];
        if ($match_type eq 'STRING') {
            push @{$out->{$token}}, @{$frame->[2]} if $frame->[1] eq $path;
        }
        elsif ($match_type eq 'REGEXP' || ($match_type eq 'SCALAR' && re::is_regexp($frame->[0]) == 1 )) {
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
                if ($val_type && 
                 ( $val_type eq 'REGEXP' || ($val_type eq 'SCALAR' && re::is_regexp($val) == 1 ))
                ) {
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
        elsif ($match_type eq 'ACCEPT') {
            push @{$out->{$token}}, @{$frame->[2]} if length $accept_variant && $frame->[1] eq $accept_variant;
        }
        else {
            warn "I don't know how to match '$match_type', skipping.\n"
        }
    }
    return $out;
}

sub detokenize_pipeline {
    my $self = shift;
    my $tokenized = shift;

    unless ($tokenized) {
        $tokenized = ['__default__'];
    }

    my @new = ();
    my $map = $self->make_map;
    my @tokens      = keys( %{$map} );

    foreach my $step ( @{$tokenized} ) {
        if ( grep { $_ eq $step } @tokens ) {
            push @new, @{$map->{$step}};
        }
        else {
            push @new, $step;
        }
    }
    return \@new;
}


#SEEALSO: Magpie

1;
