package Loader;
use strict;
use warnings;
use parent qw( Exporter );
our @EXPORT = qw( machine match );
use Scalar::Util qw(reftype blessed);

use Data::Dumper::Concise;

our @pipeline = ();
our $OM = [
    [ undef, undef, undef, undef, [] ]
];

sub add_to_pipe {
    push @pipeline, @_;
}

sub machine (&) {
    my $block = shift;
    $block->();
    my @stack = ();
    return @pipeline;
}

sub match {
    my $to_match = shift;
    my @to_add = @_;
    my $match_type = reftype $to_match || 'STRING';

    if (scalar @to_add > 1 ) {
        warn "who knows " . Dumper(\@_);
    }
    else {
        my $add_type   = reftype $to_add[0];
#        warn "types '$match_type' and '$add_type'\n";
        push @pipeline, [ [$match_type, $to_match], [$add_type, $to_add[0]] ]
    }
}

1;