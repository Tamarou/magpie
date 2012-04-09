package Magpie::Pipeline::PathMadness;
use Moose;
extends 'Magpie::Component';
with 'Magpie::Dispatcher::RequestMethod';
use Magpie::Constants;

__PACKAGE__->register_events(Magpie::Dispatcher::RequestMethod::events());

sub GET {
	my $self = shift;
	my %params = $self->uri_template_params;
    my $body = $self->response->body || '';
    $body = ref($body) eq 'ARRAY' ? join '', @$body : $body;
    my $vstring = '';
    foreach my $k (sort keys %params) {
    	$vstring .= '_' . $k . '::' . $params{$k} . '_';
    }
    $body .= 'pathmadness_' . $vstring;
    $self->response->body( $body );
    return OK;
}

1;