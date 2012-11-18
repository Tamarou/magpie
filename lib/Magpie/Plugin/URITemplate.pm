package Magpie::Plugin::URITemplate;
use Moose::Role;
#
# ABSTRACT: A Role to add URI Template-like path variable capture;
#
use Magpie::Constants;

has uri_template_param_names => (
	is			=> 'rw',
	isa			=> 'ArrayRef',
	default		=> sub {[]},
	clearer     => 'clear_params',
);

has uri_template => (
	is			=> 'rw',
	isa			=> 'Str',
	required	=> 1,
	trigger     => sub {
	    my $self = shift;
	    $self->clear_regex;
	    $self->clear_params;
	},
);

has uri_template_regex => (
	is			=> 'ro',
	isa			=> 'RegexpRef',
	lazy		=> 1,
	builder		=> '_build_regexp',
	clearer     => 'clear_regex',
);

sub _build_regexp {
		my $self = shift;
		my ($re, $names) = process_template($self->uri_template);
		$self->uri_template_param_names($names);
		return $re;
}

sub uri_template_params {
	my $self = shift;
	my $extractor = $self->uri_template_regex;
    my $names = $self->uri_template_param_names;
	my $path = $self->request->path_info;
	my @vals = ( $path =~ $extractor );
	unless (scalar @vals == scalar @{$names}) {
		warn "URI template param extraction mismatch\n";
	}

	my %params = ();

	for (my $i = 0; $i < @{$names}; $i++) {
		$params{$names->[$i]} = $vals[$i];
	}

	return wantarray ? %params : \%params;
}

sub process_template {
	my $template = shift;
	my @names = ();
	my $intoken = 0;
	my $token   = undef;
	my $transformed = '';
	#my @chars = split '', $string;

	for (split '', $template) {
		if ($_ eq '{') {
			$intoken = 1;
		}
		elsif ($_ eq '}') {
			push @names, $token;
			$transformed .= '(.*)';
			$token = undef;
			$intoken = 0;

		}
		else {
			if ($intoken) {
			   $token .= $_;
			}
			else {
				$transformed .= $_;
			}
		}
	}

	my $re = qr|$transformed|;
	return ($re, \@names);

}

no Moose::Role;

1;
