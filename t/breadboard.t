use Test::More;
use Test::Requires qw{
    Devel::Monitor
};
use FindBin;
use lib "$FindBin::Bin/lib";
use Bread::Board;

use Devel::Monitor qw(:all);

use_ok('Magpie::Machine');

my $assets = container '' => as {
    service 'somevar' => 'some value';
};

my $m = Magpie::Machine->new();

$m->assets($assets);

ok($m);

$m->pipeline(qw( Magpie::Pipeline::Breadboard::Simple ));

$m->run( {} );

print_circular_ref( \$m );

#find_cycle($m, sub { warn "\n>>>>>> CYCLE: " . Dumper(shift); });

done_testing();
__END__

