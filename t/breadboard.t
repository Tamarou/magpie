use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use Data::Dumper::Concise;
use Bread::Board;
use_ok('Magpie::Machine');

my $resources = container 'Resources' => as {
        service 'somevar' => 'some value';
};

my $m = Magpie::Machine->new();

$m->breadboard->resources( $resources );

ok( $m );

warn Dumper( $m );

$m->pipeline(qw( Magpie::Pipeline::Breadboard::Simple ));

$m->run( {} );

done_testing();