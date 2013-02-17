package Magpie::Matcher;
#ABSTRACT: Multi-purpose Dispatcher Magic

use Moose;
use Scalar::Util qw(reftype);
use HTTP::Negotiate;

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
        $out->{$token} ||= {
            input => [],
            resource => [],
            output   => [],
        };
        
        if ($match_type eq 'STRING') {
            next unless $frame->[1] eq $path;
            push @{$out->{$token}->{input}}, @{$frame->[2]->{input}}; 
            push @{$out->{$token}->{output}}, @{$frame->[2]->{output}};
            push @{$out->{$token}->{resource}}, @{$frame->[2]->{resource}};
        }
        elsif ($match_type eq 'REGEXP' || ($match_type eq 'SCALAR' && re::is_regexp($frame->[0]) == 1 )) {
            if ($path =~ /$frame->[1]/) {
                push @{$out->{$token}->{input}}, @{$frame->[2]->{input}}; 
                push @{$out->{$token}->{output}}, @{$frame->[2]->{output}};
                push @{$out->{$token}->{resource}}, @{$frame->[2]->{resource}};
            }
        }
        elsif ($match_type eq 'CODE') {
            my $temp = $frame->[1]->($env);
            if (reftype $temp eq 'HASH') {
                push @{$out->{$token}->{input}}, @{$temp->{input}}; 
                push @{$out->{$token}->{output}}, @{$temp->{output}};
                push @{$out->{$token}->{resource}}, @{$temp->{resource}};            
            }
            else {
                push @{$out->{$token}->{output}}, @{$temp};
            }
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
            if ($matched == scalar keys %{$rules}) {
                push @{$out->{$token}->{input}}, @{$frame->[2]->{input}}; 
                push @{$out->{$token}->{output}}, @{$frame->[2]->{output}};
                push @{$out->{$token}->{resource}}, @{$frame->[2]->{resource}};
            }
        }
        elsif ($match_type eq 'AUTO') {
                push @{$out->{$token}->{input}}, @{$frame->[2]->{input}}; 
                push @{$out->{$token}->{output}}, @{$frame->[2]->{output}};
                push @{$out->{$token}->{resource}}, @{$frame->[2]->{resource}};
        }
        elsif ($match_type eq 'ACCEPT') {
            if (length $accept_variant && $frame->[1] eq $accept_variant) {
                push @{$out->{$token}->{input}}, @{$frame->[2]->{input}}; 
                push @{$out->{$token}->{output}}, @{$frame->[2]->{output}};
                push @{$out->{$token}->{resource}}, @{$frame->[2]->{resource}};
            }
        }
        else {
            warn "I don't know how to match '$match_type', skipping.\n"
        }
    }
    return $out;
}

sub construct_pipeline {
    my $self = shift;
    my $tokenized = shift;

    unless ($tokenized) {
        $tokenized = ['__default__'];
    }

    my @input = ();
    my @output = ();
    my @resource = ();
    my $map = $self->make_map;
    my @tokens      = keys( %{$map} );

    foreach my $step ( @{$tokenized} ) {
        if ( grep { $_ eq $step } @tokens ) {
                push @input, @{$map->{$step}->{input}}; 
                push @output, @{$map->{$step}->{output}};
                push @resource, @{$map->{$step}->{resource}};
        }
        else {
            push @output, $step;
        }
    }
    
    if (scalar @resource == 0) {
        push @resource, 'Magpie::Resource::Abstract';
    }
    my @new = (@input, @resource, @output);
    return \@new;
}


#SEEALSO: Magpie

1;
