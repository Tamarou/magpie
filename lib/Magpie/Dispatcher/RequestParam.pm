package Magpie::Dispatcher::RequestParam;
use MooseX::Role::Parameterized;

parameter state_param => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'appstate',
);

role {
    my $p = shift;

    has 'state_param' => (
        is          => 'ro',
        isa         => 'Str',
        default     => $p->state_param,
    );
};

sub load_queue {
    my $self = shift;
    my @events = ();

    if ($self->can('init')) {
        push @events, 'init';
    }

    my $state = $self->request->param( $self->state_param );

    if ($state and $self->can($state)) {
        push @events, $state;
    }
    else {
        push(@events, 'default') if $self->can('default');
    }

    return @events;
}

1;