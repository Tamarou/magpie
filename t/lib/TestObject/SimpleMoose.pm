package TestObject::SimpleMoose;
use Moose;

has name => (
	is			=> 'rw',
	isa			=> 'Str',
	default		=> 'some name',
);

has foo => (
	is			=> 'rw',
	isa			=> 'Str',
	default		=> 'bar',
);

has favorite_holiday => (
	is			=> 'rw',
	isa			=> 'Str',
	default		=> 'Easter',
);

1;