package Magpie::Constants;
# ABSTRACT: Common Handler Control Constants;

use Moose;

sub import {
    my $pkg = caller();
    return if $pkg eq 'main';

    ( $pkg->can('meta') )
      || confess "This package can only be used in Moose based classes";

    my %exports = (
        OK            => sub () { 100 },
        DECLINED      => sub () { 199 },
        DONE          => sub () { 299 },
        OUTPUT        => sub () { 300 },
        SERVER_ERROR  => sub () { 500 },
        HANDLER_ERROR => sub () { 501 },
        QUEUE_ERROR   => sub () { 502 },
    );

    for my $symbol ( keys %exports ) {
        $pkg->meta->add_method( $symbol => $exports{$symbol} );
    }
}

# SEEALSO: Magpie, Magpie::Component, Magpie::Event

1;
__END__