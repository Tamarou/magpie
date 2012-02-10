use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Magpie::Machine;

my $m = Magpie::Machine->new();

ok( $m );

$m->pipeline(qw( Magpie::Pipeline::Moe ));

$m->run( {} );

ok(1);

done_testing();
