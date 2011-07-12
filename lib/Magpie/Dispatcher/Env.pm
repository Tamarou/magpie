package Magpie::Dispatcher::Env;
use Moose::Role;

requires 'map_events';

has event_mapping => (
    is        => 'ro',
    isa       => 'HashRef',
    builder   => 'map_events',
);

sub load_queue {
    my $self = shift;
    my $ctxt = shift;
    my $mapping = $self->event_mapping;

    my @event_names = ();
    my $env = $self->plack_request->env;

    foreach my $event ( keys( %{$mapping} )) {
        my $val = $mapping{$event};

    }
}

1;