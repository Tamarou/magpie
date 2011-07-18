use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use Bread::Board;
#use Data::Dumper::Concise;

use_ok('Magpie::Machine');

my $resources = container '' => as {
        service 'somevar' => 'some value';
};

my $m = Magpie::Machine->new();

$m->assets( $resources );

ok( $m );

$m->pipeline(qw( Magpie::Pipeline::Breadboard::Simple ));

$m->run( {} );

# these are added by the Handler classes:
ok( $m->assets->has_service('othervar'), 'asset added in handler.' );

my $other = $m->resolve_asset( service => 'othervar' );

is( $other, 'other value', 'correct value passed');
done_testing();