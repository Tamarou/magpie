use strict;
use warnings;
use Test::More;
use Magpie::Constants;

use Magpie::Event;
use Magpie::Constants;

{

    package Testy::Testerson;
    use Moose;
    with qw( Magpie::Event );
    sub default_symbol_table { Magpie::SymbolTable->new }
}

my $e = Testy::Testerson->new();

ok($e);

can_ok( $e, 'add_symbol_handler' );
can_ok( $e, 'get_symbol_handler' );

$e->add_symbol_handler( 'testy' => sub { return 100; } );

my $array_ref
    = $e->symbol_table->get_symbol( $e->_qualify_symbol_name('testy') );

cmp_ok( ref( $array_ref->[0] ), 'eq', 'CODE', "Symbol table access works." );

my @array = $e->get_symbol_handler('testy');

is_deeply( $array_ref->[0], $array[0] );

my $ret = $e->handle_symbol( {}, 'testy' );

is( $ret, 100, "Handler sub returns expected code." );

done_testing();
