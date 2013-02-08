package Core::StaticMatcher;
use Moose;

sub construct_pipeline {
	return [
		'Magpie::Pipeline::CurlyArgs' => { simple_argument => 'RIGHT' },
		'Magpie::Pipeline::CurlyArgs' => { simple_argument => 'WRONG' },
	];
}

1;
