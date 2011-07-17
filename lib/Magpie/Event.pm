package Magpie::Event;
use Moose::Role;
with qw( Magpie::Event::Symbol Magpie::Types );

use Magpie::Constants;
use Magpie::SymbolTable;
use Plack::Request;
use Plack::Response;
use Try::Tiny;
use Scalar::Util qw( blessed );
use Carp qw(cluck);
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
    isa         => 'ArrayRef[ArrayRef]',
    default     => sub { [] },
    handles     => {
        push_handlers      => 'push',
        pop_handlers       => 'pop',
        shift_handlers     => 'shift',
        unshift_handlers   => 'unshift',
        clear_handlers     => 'clear',
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

has current_handler_args => (
    is        => 'rw',
    predicate => 'has_current_handler_args',
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

    $self->free_queue();
    $self->clear_handlers();
    if ($self->has_parent_handler) {
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

    my $tuple = $self->shift_handlers;
    if ( defined $tuple ) {
        $self->current_handler( $tuple->[0] );
        $self->current_handler_args( $tuple->[1] );
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
    my $handler_args = $self->current_handler_args || {};
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
            my $error = "Fatal error loading handler class '$handler': $_ \n";
            $self->set_error({ status_code => 500, reason => $error });

        };

        return HANDLER_ERROR if $self->has_error;

        try {
            $new_handler = $handler->new(
                %{ $handler_args },
                plack_request  => $self->plack_request,
                plack_response => $self->plack_response,
                breadboard     => $self->breadboard,
            ) || die "Error loading handler $!";

            $new_handler->resource( $self->resource ) if $new_handler->can('resource');
        }
        catch {
            my $error = "Fatal error during build for class '$handler': $_\n";
            $self->set_error({ status_code => 500, reason => $error });
        };

        return HANDLER_ERROR if $self->has_error;

        $new_handler->parent_handler( $self );
        $self->register_handler( $handler => $new_handler );
    }

    if ($self->fetch_handler( $handler )) {
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
    my $handler_args = $self->current_handler_args || {};
    #warn "run handler: $handler\n";

    if ( my $h = $self->fetch_handler( $handler ) ) {
        # class may be loaded but params may be different
        my @attributes = $h->meta->get_all_attributes;
        foreach my $param (keys( %{$handler_args})) {
            foreach my $attr (@attributes) {
                my $writer_name = $attr->get_write_method;
                if ($writer_name and $writer_name eq $param) {
                    $h->$param( $handler_args->{$param} );
                }
            }
        }
        # warn "Running handler $handler \n";
        try {
            $h->run( $ctxt );

        }
        catch {
            my $error = "Fatal error running handler '$handler': $_";
            $self->set_error({ status_code => 500, reason => $_ });
        };

        # propagate errors up the handler stack
        if ( $h->has_error ) {
            $self->set_error( $h->error );
        }

        # remember, nesting.
        $self->plack_response( $h->plack_response );
        $self->breadboard( $h->breadboard );
        $self->add_to_queue( "next_in_pipe" );

    }
    else {
        return QUEUE_ERROR;
    }
    return OK;
}

#-------------------------------------------------------------------------------
# add_handler()
# Add a handler into the end of the event queue.
#-------------------------------------------------------------------------------
sub add_handler {
    my $self    = shift;
    my $handler = shift;
    my $args    = shift || {};
    if ( defined $handler && length $handler ) {
        $self->push_handlers([ $handler, $args ]);
    }
}

#-------------------------------------------------------------------------------
# add_next_handler()
# Add a handler into the front of the event queue.
#-------------------------------------------------------------------------------
sub add_next_handler {
    my $self    = shift;
    my $handler = shift;
    my $args    = shift || {};

    if ( defined $handler && length $handler ) {
        $self->unshift_handlers([$handler, $args]);
    }
}

#-------------------------------------------------------------------------------
# add_handlers( @list )
# Add a list of handlers to the event queue.
#-------------------------------------------------------------------------------
sub add_handlers {
    my $self = shift;
    my @handlers = @_;
    @handlers = $self->_make_tuples( @handlers );
    $self->push_handlers(@handlers);
}

#-------------------------------------------------------------------------------
# reset_handlers( @list )
# Replaces the current list of handlers with @list .
#-------------------------------------------------------------------------------
sub reset_handlers {
    my $self    = shift;
    my @handlers = @_;
    $self->clear_handlers;
    return $self->add_handlers( @handlers );
}

#-------------------------------------------------------------------------------
# internal convenience for regularizing potentially uneven lists of name/param
# hash pairs
#-------------------------------------------------------------------------------
sub _make_tuples {
    my $self = shift;
    my @in = @_;
    my @out = ();
    for (my $i = 0; $i < scalar @in; $i++ ) {
        next if ref( $in[$i] ) eq 'HASH';
        my $args = {};
        if ( ref( $in[$i + 1 ]) eq 'HASH' ) {
            $args = $in[$i + 1 ];
        }
        push @out, [$in[$i], $args];
    }
    return @out;
}

sub end_application {
    #warn "implement end_application already, will you?\n";
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
# each sub is examined (see Magpie::Constants, and the handle_* subs below)
# and the handler's program flow is controlled accordingly. If all subs
# return OK (200) this method does not intervene-- each sub is fired and
# we return OK to the main event loop (which will then move to the next symbol
# in the queue).
#-------------------------------------------------------------------------------
sub handle_symbol {
    my $self        = shift;
    my $ctxt        = shift;
    my $symbol      = shift;
    my $return_code = undef;

    # warn "Handling symbol: $symbol \n";
    # load each handler associated with $symbol, run them,
    # and manipulate program flow if need be based on their
    # return values
    foreach my $h ( $self->get_symbol_handler( $symbol ) ) {
        try {
            $return_code = $h->($self, $ctxt);
        }
        catch {
            $self->set_error({ status_code => 500, reason => $_ });
            #warn "Error running symbol '$symbol': $_";
        };

        if ( (!length $return_code) or ($return_code >= SERVER_ERROR) ) {
            unless ( $self->has_error ) {
                $self->set_error({
                    status_code => 500,
                    reason => "Internal error or unknown return code from symbol '$symbol'"
                });
            }
            $return_code = DONE;
        }

        return $self->control_done()     if $return_code == DONE;
        return $self->control_declined() if $return_code == DECLINED;
        return $self->control_output()   if $return_code == OUTPUT;
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

    unless ( $self->symbol_table->has_symbol($symbol) ) {
        warn "Warning: '$symbol' could not be added to the queue. Are you sure you registered it via register_events?";
        #XXX: should we die or set_error here instead?
        return;
    }

    # add events with high priority to the beginning of the stack.
    if ( defined $priority and $priority == 1 ) {
        $self->unshift_queue( $symbol );
    }
    else {
        $self->free_queue() if defined $priority and $priority == -1;
        $self->push_queue( $symbol );
    }
}

#-------------------------------------------------------------------------------
# remove_from_queue( $symbol, $priority )
#-------------------------------------------------------------------------------
sub remove_from_queue {
    my $self     = shift;
    my $symbol   = shift;
    my $priority = shift || 0;

    $symbol = $self->_qualify_symbol_name( $symbol );

    unless ( $self->symbol_table->has_symbol($symbol) ) {
        warn "Warning: Unregistered event '$symbol' could not be removed from the queue because it does not exist. Are you sure you registered it via register_events?";
        return;
    }

    my $f = 0;

    if ($priority == 0 ) {
        my @new = grep { $_ ne $symbol } @{$self->event_queue};
        $self->event_queue(\@new);
    }

    # remove the last occourence of $symbol
    elsif ( $priority == -1 ) {
        my @new = reverse grep { defined $_ } map {
            $_ ne $symbol ?
                $_ :
                $f == 1 ?
                    $_ : do{ $f=1; undef }
              } reverse( @{$self->event_queue} );
        $self->event_queue(\@new);
    }

    # otherwise, drop the first occourence of $symbol
    else {
        my @new = grep { defined $_ } map {
            $_ ne $symbol ?
                $_ :
                $f == 1 ?
                    $_ : do{ $f=1; undef }
            } @{$self->event_queue};
        $self->event_queue(\@new);
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
    return DONE;
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
        # warn "state is $state from $symbol";
        last unless $state == OK;
    }
    $self->end_application( $ctxt );
    return $self->server_status;
}

1;
