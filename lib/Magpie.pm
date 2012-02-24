package Magpie;
use Moose;

# ABSTRACT: Pipelined State Machine Plack Middleware Framework

1;
__END__

=pod

=head1 SYNOPSIS

  -----
  # static.psgi
  use Plack::Builder
  use Plack::Middleware::Magpie;

  # A static pipeline, will always load the same components
  # for every request,
  my $app = builder {
    enable "Magpie", context => {}, pipeline => [
        # main application logic
        'MyApp::Core',

        # transform the result using Template Toolkit
        'Magpie::Transformer::TT2' => { template_root => '/my/template/dir' }
    ];
  };

  -----
  # dynamic.psgi
  use Plack::Builder
  use Plack::Middleware::Magpie;

  # use the machine and match, and match_env sugar to load components
  # conditionally
  my $app = builder {
    enable "Magpie", context => {}, pipeline => [
        machine {
            # prepend an input transformer for POST and PUT requests
            match_env { REQUEST_METHOD => qr/POST|PUT/ } => ['MyApp::InputHandler'];

            # matches every request, generates core content
            match qr|^/| => ['MyApp::XMLGenerator];

            # apply different XSLT stylesheets based on the request path.
            match qr|^/blog/| => [ 'Magpie::Transformer::XSLT'
                                        => { stylesheet => '/style/blog.xsl'}];

            match qr|^/shop/| => [ 'Magpie::Transformer::XSLT'
                                        => { stylesheet => '/style/cart.xsl'}];
        }
    ];
  };



=head1 How Does Magpie Work?

=begin html

<img src="images/Magpiebasicflow.png" alt="Magpie's Basic Application Flow"/>

=end html

A typical Magpie application has three parts:

=over

=item 1

One or more L<Application Classes|/Application Classes> that contain the event
handler methods that are fired during the application's run.

=item 2

One or more L<Output Class|/Output Classes> that controls how to serialize the
application state into data that the requesting client can consume.

=item 3

An L<interface script/module|/interface script/module> that constructs the
L<Magpie::Machine> application pipeline and connects it to the wider world.

=back

=head2 External Interfaces

First, the I<interface> component:

  # sample.pm -- A Typical Magpie application as a modperl2 handler
  package sample::handler;
  use Magpie::Machine;
  use Apache::Response;
  use Apache::Const;


  sub handler {
      my $r = shift;

      # load the Application and Output classes into
      # the Magpie pipeline
      my $app = Magpie::Machine->new();
      $app->pipeline( qw(
          My::Greetings
          Magpie::Output::Scalar
      ) );

      # can be any type of Perl reference or object
      my $application_context = {};

      # execute the application pipeline
      return $app->run( $application_context );
  }

  1;

Like all ModPerl content handlers, this simple module implements a
C<handler()> method that is called whenever the URI associated with this
module is requested. Here, that method creates a new Magpie application by
calling the C<new()> constructor of the C<Magpie::Machine> class-- all Magpie
applications are an instance of that class.

By itself, this instance of the Machine class does nothing useful; we must
load the L<Application Class|/Application Classes> (or classes) that will
perform required operations and the L<Output Class|/Output Classes> that will
generate the appropriate response. We do this by calling the Machine
instance's C<pipeline()> method and passing in a list containing a mix of
either the I<Perl package names> of the classes we want to load or I<blessed
instances> of those classes. In the example above, we loaded two classes into
the Machine's application pipeline: C<My::Greetings> and
C<Magpie::Output::Scalar> by simply passing in the class names.

Finally, we set the application in motion by calling the Machine instance's
C<run()> method. This method takes a single argument that may contain any sort
of Perl reference (hash reference, array reference, blessed object). and,
whatever data structure or object that is passed as that argument is made
available to all methods in the Application and Output classes that are called
as the application runs (more about how this works in the L<next
section|/Application Classes>). When the C<run()> method is called, each class
that was passed in via the C<pipeline()> method is loaded in the order they we
passed and all I<event handler> methods implemented in those classes that
match the current application state are called. When the event handlers from
one application class are completed the Machine loads the next class and calls
its methods-- and so on, until the last method in the Output class is called,
at which point the response has been sent and the application pipeline
terminates.

=head1 Application Classes

In Magpie, application classes are implemented as subclasses of an event
model. This underlying Event class is responsible for registering event
handlers with Magpie's internal queue and for determining which of those
registered handlers will be fired in response to the current state. In short,
the Event class determines which state the application is in, and which of the
registered event handler methods will be fired in response to that state.
Usually, the details of mapping states to events are never visible to the
developer beyond the initial choice of which Event model to use as a base
class (different Event classes use different conditions to determine
application state). In daily practice, you simply implement and register the
events that you application needs and let Magpie do the rest.

  # Greetings.pm -- A Magpie Application class that greets the
  #                 user based on application state
  package MyApp::Pipeline::Greetings;
  use Moose;

  # inherit from the base Component class.
  extends 'Magpie::Component';

  # determines the application state based on the value
  # of a specific form/query param ala CGI::Application.
  with 'Magpie::Dispatcher::RequestParam' => { state_param => 'appstate' };

  # Import handler
  use Magpie::Constants;

  # register the event handlers for this class
  __PACKAGE__->register_events( qw( morning afternoon evening default) );

  # implement the event handlers

  sub morning {
      my $self = shift;
      my $ctxt = shift;

      $ctxt->{message} = 'Good morning!';

      return OK;
  }

  sub afternoon {
      my $self = shift;
      my $ctxt = shift;

      $ctxt->{message} = 'Good afternoon!';

      return OK;
  }

  sub evening {
      my $self = shift;
      my $ctxt = shift;

      $ctxt->{message} = 'Good evening!';

      return OK;
  }

  # will be called if no matching state is found
  sub default {
      my $self = shift;
      my $ctxt = shift;

      $ctxt->{message} = "I'm not sure what time of day it is!";

      return OK;
  }

  1;

First, notice that the application class is a subclass of the
C<Magpie::Component>.  Through this interface (and the roles it consumes), you get access to the core attributes and methods of the Magpie application framework (see the section titled 'know thy $self' below). In C<Magpie::Event::Simple> you register
a list of state events via the required registerEvents() function. The event
model then determines which event handler method to fire by examining the
value of a specific querystring or POSTed form parameter. (The default param
is named "appstate" but that can be overridden by implementing the
C<state_param()> method and returning some other value). If the underlying
Event model finds a registered event whose name matches the value returned by
the C<state_param()> method, the event handler method named
C<event_B<<eventname>>> is called. So, for example, a request to the URI that
exposes the class above like the following:

  http://example.org/apps/greet?appstate=morning

would cause the C<event_morning()> method to be called. If no matching state
is found, the C<event_default()> event handler method is called as a fallback.
In addition, most Magpie Event model classes also implement an C<event_init()>
handler and an C<event_exit()> handler. These methods are optional and, if
implemented, C<event_init()> will be called after the event queue is
initialized but before the first state-determined event handler is fired while
C<event_exit()> is called just before the application exits.

Note that C<Magpie::Event::Simple> (that determines application state based on
a single form param) is only one possible event model and you are free to
choose another and/or write your own-- even mixing application classes based
on different models within the same application pipeline. This flexibility is
one of Magpie's key strengths.

=head2 Event Handler Methods

Every Magpie Application class will implement one or more I<event handler
methods> that will be called conditionally based on the state that is
determined by the underlying event model. It is within these methods that the
real business of the application takes place. In the above example, these
methods merely set a key in the application-wide C<$ctxt> hash reference, but
there is no limit to what you can do. Remember, part of the point of Magpie is
to separate state detection from application code-- this is achieved by having
the event model parent class determine the state then call the event handler
methods that implement the code that should be run for that state.

Each event handler method is passed two arguments: the C<$self> class instance
member, and a special I<application context> member (named C<$ctxt> in the
examples above).

=head3 Know Thy $self

In Magpie Application classes the C<$self> class instance member offers access to a handful of common attributes and methods:

=over

=item C<< B<< $self->request >> >>

This offers acccess to C<Plack::Request> object representing the current client request.

Example:

  if ( $self->request->method eq 'POST' ) {
    ...
  }

=back

=head3 Keeping Things In $ctxt

The second argument passed to each event handler method is the I<context
member> (named $ctxt in these examples). The context member-- which can be any
kind of Perl object or reference to another data structure-- is passed as the
sole argument to the application pipeline's run() method.

  # in your interface module/script:
  my $handler = builder {
      enable "Magpie", context => $app_context, pipeline => [
         ...
      ];
  };
  ...

  # then later, in the event handler methods in your application classes
  sub myevent {
      my $self = shift;
      my $ctxt = shift; # same object/data as $app_context above
  }

In keeping with Magpie's general goal of letting developers do what makes the
most sense to them, Magpie does not enforce many rules about what the $ctxt
can be, or how it can be used. The only constraint is that the context member
I<must> be a scalar or reference. Typically, the context member is a reference
to a Perl hash, an anonymous hash reference, or a blessed object. Again, some
examples that might appear in your in your interface module/script:

  # use a reference to an existing hash
  my %context = (
      template_dir => '/usr/local/my/app/templates',
      default_template => 'index.xsl',
  );

  my $handler = builder {
      enable "Magpie", context => \%context, pipeline => [
         ...
      ];
  };

  # some advanced apps do well to make the context an object
  # that implements is own set of methods
  my $context = My::Application::ContextMember->new( %args );

  my $handler = builder {
      enable "Magpie", context => $context, pipeline => [
         ...
      ];
  };

When no context member is explicitly passed into the Magpie machine an anonymous hash reference is used as a fallback.

  # no $ctxt is passed in
  my $handler = builder {
      enable "Magpie", pipeline => [
         ...
      ];
  };

  # then later...
  sub myevent {
      my $self = shift;
      my $ctxt = shift; # now an anonymous hashref
  }

Obviously, the role of the context member will vary greatly depending upon
your coding style and the needs of the application. In general, though, the
most common use of the $ctxt is to accumulate the data needed to render the
proper output for the current request. For example, if you are using the
Template Toolkit Transformer class (Magpie::Transformer::TT2) you might use a plain hash reference as the context member, then use it to capture the template name and variables that your templates depend on to deliver the content.


=head2 Event Handler Return Codes

Each event handler method must return one of a number of I<event handler
return codes>. The codes signal Magpie's internal event loop about what to do
after the current event handler method is finished. The codes themselves are
numeric, but are implemented as convenient Perl constants via the
C<Magpie::Constants> module so you do not have to try to remember what the
numeric codes are (this is similar to the way the C<Apache::Constants> module
works for HTTP return codes).

 use Magpie::Constants;

 sub myevent {
     my $self = shift;
     my $ctxt = shift;

     # do a little dance...

     return OK;
 }

The most common return codes and their effects on the application's behavior are as follows:

=over

=item C<< B<< OK >> >>

Returning C<OK> from you event handler method signals Magpie that everything
went as expected during the method's run and that it is safe to continue.

  sub event_init {
      my $self = shift;
      my $ctxt = shift;

      # actual application behavior here

      # everything went well, continue on...
      return OK;
  }

=item C<< B<< DECLINED >> >>

Returning C<DECLINED> from your event handler method tells Magpie's internal
event queue to skip to the next application or output class in the pipeline.
Any other methods in the current application class that would usually be fired
based on the current state will be skipped.

  sub init {
      my $self = shift;
      my $ctxt = shift;

      unless ( defined $ctxt->{some_required_data} ) {
          # we don't have the data we need to continue
          $ctxt->{error_message} = "Insufficient data for init event";
          return DECLINED;
      }

      # otherwise continue on...
      return OK;
  }

=item C<< B<< OUTPUT >> >>

Where the C<DECLINED> return code signals Magpie to skip to the I<very next>
class in the pipeline, returning C<OUTPUT> from your event handler method
tells Magpie's internal event queue to skip to I<very last> class in the
application pipeline (which is presumed to be the Output class for the current
application).

  sub event_init {
      my $self = shift;
      my $ctxt = shift;

      unless ( my $user = $self->query->cookie('app_user') ) {
          # like DECLINED above, but set a redirect
          # header and skip directly to Output phase
          $self->redirect('/login.xml');
          return OUTPUT;
      }

      # otherwise continue on...
      return OK;
  }

=item C<< B<< DONE >> >>

Returning C<DONE> from your event handler method stops the application
pipeline dead in its tracks. All subsequent classes that may be in the
pipeline are skippedIt is rarely used, given it
typically stops the application before any data is sent to the client, but it
can be useful for sending appropriate HTTP response codes.

  sub event_init {
      my $self = shift;
      my $ctxt = shift;

      unless ( -f $ctxt->{some_required_file} ) {
          # we don't have the some crucial file needed to proceed
          # so throw a 404 Not Found response while stopping the
          # application
          $self->response->status(404);
          return DONE;
      }

      # otherwise continue on...
      return OK;
  }


=back

=head1 References

=over

=item L<http://foldoc.doc.ic.ac.uk/foldoc/foldoc.cgi?finite+state+machine>

FOLDOC definition of Finite State Machines.

=back


1;
