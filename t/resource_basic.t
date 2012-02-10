use Test::More;
use strict;
use warnings;
use Magpie::Constants;
use Magpie::Resource;

{
    package Testy::Testerson;
    use Moose;
    extends 'Magpie::Resource';
}

my $r = Testy::Testerson->new();

ok( $r );
can_ok( $r, qw(GET POST PUT DELETE HEAD) );

my $code = $r->GET();

is( $code, Magpie::Event->DONE() );

ok( $r->has_error );

my $error = $r->error;

ok( $error );

my $resp = $error->();

ok( $resp );

# 501 is "not implemented"

is( $resp->[0], 501 );

done_testing();
