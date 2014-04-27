package Magpie::Matcher;
#ABSTRACT: Multi-purpose Dispatcher Magic

use Moose;
use Scalar::Util qw(reftype);
use HTTP::Negotiate;
use Data::Printer;

has plack_request => (
    is          => 'ro',
    isa         => 'Plack::Request',
    required    => 1,
    trigger     => \&choose_variant,
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

has evaluation_map => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[ArrayRef]',
    handles => {
        has_candidate => 'exists',
        get_candidate => 'get',
    },
    lazy_build => 1,
);

sub _build_evaluation_map {
    my $self = shift;
    my $candidates = $self->match_candidates;
    my $evaled = {};
    my @submatches = ();
    my @to_skip;
    # first, eval the frames to see what matches.
    foreach my $frame (@{$candidates}) {
        my @components = ();
        my $machine_token = $frame->[3],
        my $match_token = $frame->[4];
        $evaled->{$machine_token}  ||= [];
        my $added = $self->eval_match($frame);
        if (scalar @{$added} > 0) {
            my @subs_here = grep {/__MATCH__/} @{$added};
            push @submatches, @subs_here;
            push @{$evaled->{$machine_token}}, [$match_token, $added];
        }
        else {
            my @subs_here = grep {/__MATCH__/} @{$frame->[2]};
            push @to_skip, @subs_here;
        }
    }

    # now that we know what matches, flatten the pipelines by resolving the
    # match tokens
    my $out = {};
    foreach my $machine (keys( %{$evaled} )) {
        $out->{$machine} = [];
        foreach my $slot (@{$evaled->{$machine}}) {
            next if scalar grep { $_ eq $slot->[0] } (@submatches, @to_skip);
            my $components = resolve($evaled->{$machine}, $slot->[1]);
            foreach my $component (@{$components}) {
                if ($component eq '__RESET__') {
                    $out->{$machine} = [];
                    next;
                }
                push @{$out->{$machine}}, $component;
            }
            #push @{$out->{$machine}}, @{$components};
        }
    }
    return $out;
}



has accept_matrix => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[ArrayRef]',
    default => sub { [] },
);

has accept_variant => (
    is      => 'rw',
    isa     => 'Str|Undef',
    #lazy_build => 1,
);

sub choose_variant {
    my $self = shift;
    my $plack_request = shift;
    my $accept_matrix = $self->accept_matrix;
    if ($accept_matrix) {
        my $variant = HTTP::Negotiate::choose($accept_matrix, $plack_request->headers);
        $self->accept_variant($variant);
    }

}

sub _build_accept_variant {
    my $self = shift;
    my $ret = undef;
    my $accept_matrix = $self->accept_matrix;
    if ($accept_matrix) {
        $ret = HTTP::Negotiate::choose($accept_matrix, $self->plack_request->headers);
    }
    return $ret;
}

sub resolve {
    my $machine = shift;
    my $component_list = shift;
    my $stack = shift || [];
    foreach my $component (@{$component_list}) {
        if ($component =~ /__MATCH__/) {
            my @new_list = ();
            foreach my $thing (@{$machine}) {
                if ($thing->[0] eq $component) {
                    push @new_list, @{$thing->[1]};
                }
            }
            my $resolved = resolve($machine, \@new_list);
            push @{$stack}, @{$resolved} if $resolved;
        }
        else {
            push @{$stack}, $component;
        }
    }
    return $stack;
}

sub eval_match {
    my $self = shift;
    my $frame = shift;
    my $req = $self->plack_request;
    my $env = $req->env;
    my $path = $req->path_info;
    my $accept_variant = $self->accept_variant;
    my @out = ();

    my $match_type = $frame->[0];
    if ($match_type eq 'STRING') {
        push @out, @{$frame->[2]} if $frame->[1] eq $path;
    }
    elsif ($match_type eq 'REGEXP' || ($match_type eq 'SCALAR' && re::is_regexp($frame->[0]) == 1 )) {
        push @out, @{$frame->[2]} if  $path =~ /$frame->[1]/;
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
        push @out, @{$frame->[2]} if $matched == scalar keys %{$rules};
    }
    elsif ($match_type eq 'AUTO') {
        push @out, @{$frame->[2]};
    }
    elsif ($match_type eq 'ACCEPT') {
        push @out, @{$frame->[2]} if length $accept_variant && $frame->[1] eq $accept_variant;
    }
    elsif ($match_type eq 'RESET') {
        push @out, '__RESET__';
    }
    else {
        warn"I don't know how to match '$match_type', skipping.\n"
    }
    return \@out;
}

sub machine_token_lookup {
    return shift->token_lookup(@_, 3);
}

sub match_token_lookup {
    return shift->token_lookup(@_, 4);
}

sub token_lookup {
    my $self = shift;
    my $token = shift || '__default__';
    my $index = shift || 4;
    my $candidates = $self->match_candidates;
    my $ret = [];
    foreach my $frame (@{$candidates}) {
        if ($frame->[$index] eq $token) {
            push @{$ret}, $frame;
        }
    }
    return $ret;
}


sub construct_pipeline {
    my $self = shift;
    my $tokenized = shift;

    unless ($tokenized) {
        $tokenized = ['__default__'];
    }

    my @new = ();
    my $map = $self->evaluation_map;
    my @tokens = keys( %{$map} );
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
