package Loader;
use strict;
use warnings;
use parent qw( Exporter );
our @EXPORT = qw( machine match match_env );
use Scalar::Util qw(reftype blessed);

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

use Data::Dumper::Concise;

sub build_machine {
    my $req = shift;
    my $env = $req->env;
    my $path = $req->path_info;
    my @out = ();
    foreach my $frame (@STACK) {
        warn "frame " . Dumper($frame);
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
1;