package TestObject::SimpleMoose;
use Moose;

has name => (
	is			=> 'rw',
	isa			=> 'Str',
	default		=> 'some name',
	#required	=> 1,
);

1;