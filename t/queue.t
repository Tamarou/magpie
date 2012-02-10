use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use Magpie::Machine;

my $m = Magpie::Machine->new();

ok( $m );

my $pkg = $m->meta->name;

sub test_event          { return 'test_event'  }
sub test_event1         { return 'test_event1' }
sub test_event2         { return 'test_event2' }
sub priority1           { return 'priority1'   }
sub only_I_will_run_now { return 'only_I_will_run_now' };

my @list = qw(test_event test_event1 test_event2 priority1 only_I_will_run_now);
map { $m->symbol_table->add_symbol("$pkg." . $_,\&$_) } @list;

$m->add_to_queue('test_event');

is $m->event_queue->[0], 'Magpie::Machine.test_event', 'symbol added to the right slot';

$m->add_to_queue( 'test_event1' );
$m->add_to_queue( 'test_event2' );
$m->add_to_queue( 'priority1', 1 );

is scalar @{ $m->event_queue }, 4, 'queue size correct.';
is $m->event_queue->[0], "$pkg.priority1", 'priority queuing worked.';

$m->add_to_queue( 'only_I_will_run_now', -1 );
is scalar @{ $m->event_queue }, 1, 'queue size changed appropriately.';
is $m->event_queue->[0], "$pkg.only_I_will_run_now", 'exclusive queuing worked.';

$m->free_queue;
is scalar @{ $m->event_queue }, 0, 'free_queue works.';

$m->add_to_queue( 'test_event' );
$m->add_to_queue( 'test_event1' );
$m->add_to_queue( 'test_event2' );
$m->add_to_queue( 'priority1' );
$m->add_to_queue( 'test_event' );
$m->add_to_queue( 'test_event1' );
$m->add_to_queue( 'test_event2' );
$m->add_to_queue( 'priority1' );

is scalar @{ $m->event_queue }, 8, 'queue reloaded.';

# remove all test_event1
$m->remove_from_queue( 'test_event1' );

is scalar( grep { $_ eq "$pkg.test_event1" } @{ $m->event_queue }), 0, 'remove_from_queue w/out arguments nukes all instances of that symbol.';

# remove first occurance of test_event2
$m->remove_from_queue( 'test_event2', 1 );

is scalar( grep { $_ eq "$pkg.test_event2" } @{ $m->event_queue }), 1, 'remove_from_queue with a priority of 1 nukes one instance of that symbol.';

is $m->event_queue->[3], "$pkg.test_event2", 'first instance removed, second instance in place.';

# remove last occurance of priority1
$m->remove_from_queue( 'priority1', '-1' );

is scalar( grep { $_ eq "$pkg.priority1" } @{ $m->event_queue }), 1, 'remove_from_queue with a priority of -1 nukes one instance of that symbol.';

is $m->event_queue->[1], "$pkg.priority1", 'last instance removed, first instance in place.';

# make sure that symbols resolve to their subs.
$m->free_queue;

$m->add_to_queue( 'test_event' );
$m->add_to_queue( 'test_event1' );
my $event = $m->shift_queue;

is $event, "$pkg.test_event", 'shift_queue returns the correct symbol.';
is $m->event_queue->[0], "$pkg.test_event1", 'shift_queue moves the next symbol up the stack.';

done_testing();
