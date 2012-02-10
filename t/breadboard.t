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

# these are added by the Handler classes:
ok( $m->assets->has_service('othervar'), 'asset added in handler.' );

my $other = $m->resolve_asset( service => 'othervar' );

is( $other, 'other value', 'correct value passed');

# check a few common internals
my $resource = $m->resolve_internal_asset( service => 'default_resource' );
ok( $resource );
isa_ok($resource, 'Magpie::Resource::Abstract');

done_testing();
