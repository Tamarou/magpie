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

1;