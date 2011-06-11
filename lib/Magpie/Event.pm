package Magpie::Event;
use Moose::Role;
with qw( Magpie::Event::Symbol Magpie::Types );

use Magpie::Constants;
use Magpie::SymbolTable;
use Plack::Request;
use Plack::Response;
use Try::Tiny;
use Carp;
BEGIN { $SIG{__DIE__} = sub { Carp::confess(@_) } }
use Data::Dumper::Concise;

has plack_request => (
    is          => 'rw',
    isa         => 'Plack::Request',
    default     => sub { Plack::Request->new({}); },
    reader      => 'request',
);

has plack_response => (
    is          => 'rw',
    isa         => 'Plack::Response',
    default     => sub { Plack::Response->new(200); },
    reader      => 'response',
);

has symbol_table => (
    is          => 'rw',
    isa         => 'Magpie::SymbolTable',
    default     => sub { return Magpie::SymbolTable->new },
    required    => 1,
);

has parent_handler => (
    is          => 'rw',
    predicate   => 'has_parent_handler',
);

has error => (
    is          => 'rw',
    isa         => 'SmartHTTPError',
    coerce      => 1,
    predicate   => 'has_error',
    writer      => 'set_error',
);

has handlers => (
    traits      => ['Array'],
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    default     => sub { [] },
    handles     => {
        push_handlers      => 'push',
        pop_handlers       => 'pop',
        shift_handlers     => 'shift',
        unshift_handlers   => 'unshift',
    },

);

has event_queue => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        push_queue      => 'push',
        pop_queue       => 'pop',
        shift_queue     => 'shift',
        unshift_queue   => 'unshift',
        free_queue      => 'clear',
    },
);

has registered_handlers => (
    traits    => ['Hash'],
    is        => 'rw',
    isa       => 'HashRef[Object]',
    default   => sub { {} },
    handles   => {
        register_handler    => 'set',
        fetch_handler       => 'get',
        unregister_handler  => 'delete',
    },
);

has current_handler => (
    is        => 'rw',
    predicate => 'has_current_handler',
    handles   => {
        run_current_handler => 'run',
    },
);

sub BUILD{
    my $self = shift;
    $self->init_common_symbols();
    $self->init_symbols() if $self->can('init_symbols');
};

# Class methods
our %registered_events = ();
__PACKAGE__->register_events(qw( next_in_pipe load_handler run_handler ) );

sub register_events {
    my $pkg = shift;
    if ( scalar @_ ) {
        $registered_events{$pkg} ||= [];
        push @{ $registered_events{$pkg} }, @_;
    }

    return $pkg->registered_events;
}

sub registered_events {
    my $thing = shift;
    my $pkg = ref( $thing ) ? $thing->meta->name : $thing;

    #warn "in $pkg REG'D: " . Dumper( \%registered_events );
    my $ref = $registered_events{$pkg} || [];
    return @{ $ref };
}

#-------------------------------------------------------------------------------
# stop_application() stops everything dead in its tracks, potentially
# calling itself for all parent handlers as well.
# DO NOT confuse this with the harmless end_application() which only adds
# a hook for doing clean-up, etc.
#-------------------------------------------------------------------------------
sub stop_application  {
    my $self = shift;
    my $ctxt = shift;

    $self->free_queue;
    if (defined $self->parent_handler) {
        $self->parent_handler->stop_application;
    }
}

#-------------------------------------------------------------------------------
# next_in_pipe
# Event queue method for transitioning from one handler to the next.
#-------------------------------------------------------------------------------
sub next_in_pipe {
    my $self = shift;
    my $ctxt = shift;

    my $handler = $self->shift_handlers;
    if ( defined $handler ) {
        $self->current_handler( $handler );
        $self->add_to_queue( 'load_handler' );
    }

    return OK;
}

#-------------------------------------------------------------------------------
# load_handler($context)
# Event queue method that checks to see if the currently selected handler
# class has been instantiated and registered in the loaded_handler table. If
# not, it loads that class, calls its constructor, sets the current Machine
# as the parent handler, and registers the handler in loaded_handler.
# It then adds the 'run_handler' method to the event queue to keep the pipline
# "moving" forward.
#-------------------------------------------------------------------------------
sub load_handler {
    my $self = shift;
    my $ctxt = shift;

    my $handler = $self->current_handler;
    #warn "load: current handler: $handler \n";
    unless ( defined $self->fetch_handler( $handler ) ) {
        # we only make it here if the app class was passed
        # to the pipeline as the *name* of a class, rather
        # than a blessed instance
        my $new_handler;

        try {
            Class::MOP::load_class( $handler );
        }
        catch {
            my $error = $_;
            warn "Fatal error loading handler class '$handler': $error\n";
            return HANDLER_ERROR;
        };

        try {
            $new_handler = $handler->new(
                plack_request  => $self->plack_request,
                plack_response => $self->plack_response,
            ) || die "Error loading handler $!";
        }
        catch {
            my $error = $_;
            warn "Fatal error during build for class '$handler': $error\n";
            return HANDLER_ERROR;
        };

        $new_handler->parent_handler( $self );
        $self->register_handler( $handler => $new_handler );
    }
    if ( defined $self->fetch_handler( $handler ) ) {
        $self->add_to_queue( "run_handler" );
    }
    return OK;
}

#-------------------------------------------------------------------------------
# run_handler($context)
# Run the instance of the currently selected handler class, passing in the
# application's context member. This method is called by the parent classes'
# event queue (see init_queue() in this class and
#-------------------------------------------------------------------------------
sub run_handler {
    my $self = shift;
    my $ctxt = shift;

    my $handler = $self->current_handler;
    if ( my $h = $self->fetch_handler( $handler ) ) {
        warn "Running handler $handler \n";
        try {
            $h->run( $ctxt );

        }
        catch {
            my $error = $_;
            warn "error running handler '$handler': $error";
        };

        # propagate errors up the handler stack
        if ( $h->has_error ) {
            my $wtf = $h->error;
            $self->set_error( $wtf );
        }

        $self->add_to_queue( "next_in_pipe" );

    }
    else {
        return QUEUE_ERROR;
    }
    return OK;
}






sub end_application {
    warn "implement end_application already, will you?\n";
}

has server_status => (
    is          => 'rw',
    isa         => 'Int',
    default     => sub { 200 },
);

sub init_common_symbols {
    my $self = shift;
    $self->add_symbol_handler( next_in_pipe => \&next_in_pipe );
    $self->add_symbol_handler( load_handler => \&load_handler );
    $self->add_symbol_handler( run_handler  => \&run_handler );
}

#-------------------------------------------------------------------------------
# handle_symbol( $context, $symbol_name )
# Here's teh beef!
# Accepting the current context member and a symbol name as arguments, this
# method fetches the list of handler subs associated with $symbol_name and
# fires each of them in turn (passing in the $context). The return codes from
# each sub is examined (see SAWA::Constants, and the handle_* subs below)
# and the handler's program flow is controlled accordingly. If all subs
# return OK (200) this method does not intervene-- each sub is fired and
# we return OK to the main event loop (which will then move to the next symbol
# in the queue).
#-------------------------------------------------------------------------------
sub handle_symbol {
    my $self        = shift;
    my $ctxt        = shift;
    my $symbol      = shift;
    my $return_code;

    warn "Handling symbol: $symbol \n";
    # load each handler associated with $symbol, run them,
    # and manipulate program flow if need be based on their
    # return values
    foreach my $h ( $self->get_symbol_handler( $symbol ) ) {
        try {
            $return_code = $h->($self, $ctxt);
        }
        catch {
            my $error = $_;
            warn "Error running symbol '$symbol': $error";
        };
        return $self->control_done()     if $return_code == DONE;
        return $self->control_declined() if $return_code == DECLINED;
        return $self->control_output()   if $return_code == OUTPUT;
        if ($return_code >= SERVER_ERROR) {
            warn("Internal error or unknown return code from symbol $symbol");
            return $return_code;
        }
    }
    return OK;
}

sub init_queue {
    my $self = shift;
    my $ctxt = shift;

    # always first
    $self->add_to_queue( 'next_in_pipe' );
    my $pkg = $self->meta->name;
    my @event_names = ();

#     if ( $self->has_dispatcher ) {
#         # XXX: pluggable dispatcher here
#     }
    if ( $self->can('load_queue') ) {
        @event_names = $self->load_queue($ctxt);
    }

    foreach my $event_name ( @event_names ) {
        $self->add_to_queue( $event_name );
    }

    return OK;
}

#-------------------------------------------------------------------------------
# add_to_queue( $symbol, $priority )
#-------------------------------------------------------------------------------
sub add_to_queue      {
    my $self     = shift;
    my $symbol   = shift;
    my $priority = shift;

    #warn "add to queue $symbol";
    $symbol = $self->_qualify_symbol_name( $symbol );
    warn("warning: $symbol could not be added to the queue")
        unless $self->symbol_table->has_symbol($symbol);

    # add with hi priority first
    #
    if ( defined $priority and $priority == 1 ) {
        $self->unshift_queue( $symbol );
    }
    else {
        $self->free_queue() if defined $priority and $priority == -1;
        $self->push_queue( $symbol );
    }
}

################################################################################
# Control handlers.
################################################################################
# Event handlers that manage program flow in response to the control
# codes returned from the various handler subs.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# control_done()
# Fires when user returns DONE (299) from their handler sub. Is expected to
# stop the application immediately.
#-------------------------------------------------------------------------------
sub control_done {
    my $self = shift;
    $self->stop_application;
    return OK;
}

#-------------------------------------------------------------------------------
# control_declined()
# Fires when user returns DECLINED (199) from their handler sub. Is expected to
# nukes the rest of the events associated with the current handler and move
# to the next handler class in the queue.
#-------------------------------------------------------------------------------
sub control_declined {
    my $self = shift;
    $self->free_queue;
    return OK;
}

#-------------------------------------------------------------------------------
# control_output()
# Fires when user returns DECLINED (300) from their handler sub. Is expected to
# cause the queue to jump immediately to the Output handler and its queued subs.
#-------------------------------------------------------------------------------
sub control_output {
    my $self = shift;

    my $new_handlers = [];
    if ( defined $self->{parent_handler}{handlers} ) {

        # XXX: this is lame because it assumes that the last
        # parent handler is the Output class
        # I'll fix it if it really becomes an issue in Real Life(tm)
        # -ubu

        push @{$new_handlers}, $self->{parent_handler}{handlers}->[-1];
        $self->free_queue;
        $self->{parent_handler}{handlers} = $new_handlers;
    }
    return OK;
}

sub run {
    my $self  = shift;
    my $ctxt  = shift;
    my $state = OK;

    $ctxt ||= {};

    # reinit per each run required for pipelining
    $self->init_queue($ctxt);

    while ( my $symbol = $self->shift_queue() ) {
        $state = $self->handle_symbol( $ctxt, $symbol );
        # if an error occours here we must stop!
        last unless $state == OK;
    }
    $self->end_application( $ctxt );
    return $self->server_status;
}

1;
