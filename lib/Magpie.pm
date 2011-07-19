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

  # A static pipeline, will load the same components
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


=head2 Altered States

In general, an application can be seen as being in (or having) a series of
I<application states>. Consider the typical online registration application.
First, the user is presented with an HTML form into which they type their
desired username, password, personal details and other information. We can
think of this as the "prompt state" since the core action involves
I<prompting> the user to sign up. Once the user has filled in the form, they
hit the submit button to send the input to a URL on the server that implements
an interface that is able to read that incoming data. Once the request if
received, the data is often verified for fitness-- first by logic on the
server side that verifies that the data is complete and appropriate; then by
the user, who is given a read-only HTML page reflecting his or her input for
review. Let's call this the "validation state". Presented with the information
they have entered, the user may choose to return to the prompt state by
clicking a "Make Changes" button, or to proceed with registration by clicking
the "Register" button. (Note that the application itself often proactively
returns to the prompt state if it finds the user's input to be unfit). When
both the user and the system are satisfied with the input, the verified data
is sent to the server by clicking the "Register" button presented during the
validation state. The server receives the data, creates the new user account,
and responds with an HTML document containing a polite message thanking them
for registering. We'll call this the "complete state".

In short, we can say that the typical user registration application is a
single entity that can be in one or another of three distinct states (prompt,
validation, and complete).

  ----------               --------------                   ------------
  | Prompt |               | Validation |                   | Complete |
  | State  |-[User Input]->| State      |-[Data Accepted]-->| State    |
  ----------               --------------                   ------------
      ^------[Data Rejected]------|

      State Diagram for Online Registration



Despite the fact that this principle of state-based development and design is
understood (if only intuitively) by most experienced Web developers, much of
the code running on the Web today remains a mix of blocks of real
application-level programming wrapped by largely redundant application state
detection logic. We have learned through experience the benefits of separating
an application's logic from its presentation, yet we persist in mixing
application state detection with code that reacts to those states. Magpie
exists because its developers and users have found that separating application
state detection from behavioral logic offers similar benefits to those that
come from drawing a clear line between application logic and presentation--
namely, the logical division of labor/time, and the ability to create
uncluttered more maintainable code faster, and the freedom to reuse resources
by decoupling distinct aspects of the application implementation.

Magpie works by mapping I<application states>, determined by user input and
other factors, to I<event handler methods>, that implement the behavior
associated with that state. In Magpie, developers need only register and
implement the specific bits of code that react to a given application state,
Magpie makes sure that correct event (or events) are fired.

Magpie's core distribution provides a simple Web application infrastructure
along with a few commonly useful state-to-event mapping mechanisms that have
proven themselves useful over time, but makes no other presumptions or
proscriptions about the design or implementation of a given application. The
point is to reduce brittleness and redundancies while ensuring that developers
are free to implement their application in the way that makes most sense to
them.


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

One L<Output Class|/Output Classes> that controls how to serialize the
application state into data that the requesting client can consume.

=item 3

An L<interface script/module|/interface script/module> that constructs the
Magpie::Machine application pipeline and connects it to the wider world,
usually via an HTTP server like Apache.

=back

Note that these three elements correspond, in order, to the Model, Viewport,
and Controller elements of the MVC design pattern.

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
handlers with Magpie'S internal queue and for determining which of those
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
  package Greetings;
  use strict;

  # inherit from the Event::Simple event model which
  # determines the application state based on the value
  # of a specific form/query param.

  use base qw( Magpie::Event::Simple );
  use Magpie::Constants;

  # register the event handlers for this class
  sub registerEvents {
      return qw( morning afternoon evening );
  }

  # implement the event handlers

  sub event_morning {
      my $self = shift;
      my $ctxt = shift;

      $ctxt->{message} = 'Good morning!';

      return OK;
  }

  sub event_afternoon {
      my $self = shift;
      my $ctxt = shift;

      $ctxt->{message} = 'Good afternoon!';

      return OK;
  }

  sub event_evening {
      my $self = shift;
      my $ctxt = shift;

      $ctxt->{message} = 'Good evening!';

      return OK;
  }

  # will be called if no matching state is found
  sub event_default {
      my $self = shift;
      my $ctxt = shift;

      $ctxt->{message} = "I'm not sure what time of day it is!";

      return OK;
  }

  1;

First, notice that the application class is a subclass of the
C<Magpie::Event::Simple> Event model. In C<Magpie::Event::Simple> you register
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

In Magpie Application classes the C<$self> class instance member is special:
not only does it offer access to the methods in the Event model superclass and
any custom methods implemented in the user-visible parts of the application
class, it also offers access to a small set of application-wide convenience
methods:

=over

=item C<< B<< $self->query >> >>

This offers access to the C<CGI.pm> or C<Apache::Request> object that can be
used from any Application or Output class. All methods available to those
classes can be accessed via the C<< $self->query >> method.

Example:

  if ( $self->query->method eq 'POST' ) {
    ...
  }

=item C<< B<< $self->uri >> >>

This is a factory methods for C<URI.pm> objects. It accepts a single URI as
string as its sole argument and returns the C<URI> object. If called without
an argument the current application URL (including querystring and path info)
is used during object creation. See the documentation for C<URI.pm> for
detailed info about the object this method returns.

=item C<< B<< $self->redirect >> >>

This method accepts a single URL string as its sole argument. If set, this
method will cause the the Output class to send a redirect response to the
client rather than performing any content transformations, template processing
or other Output class methods. Note, though that setting a value for this
method will B<not> immediately stop the current event handler. If you want to
stop the application pipeline you can do that by returning C<DONE> from your
even handler method (see the section on L<Event Handler Return Codes|Event
Handler Return Codes> below).

Example:

  # if $some_var is not defined, set the redirection URI and
  # skip directly to the application output phase
  unless ( defined( $some_var ) ) {
      $self->redirect('/login.html');
      return Magpie::OUTPUT;
  }

=item C<< B<< $self->header >> >>

Accepting a single key => value pair, this method sets an outgoing HTTP header
on the outgoing response. Multiple calls add multiple headers. Direct access
to the list of outgoing header key => value pairs is available via the C<<
$self->headers >> method. Incoming request headers are available via the
$self->query (C<CGI> or C<Apache::Request>) object.

Example:

  # set a strange custom outgoing header
  $self->header( Bogus => 'IRBaboon' );

  # set multiple headers at once
  $self->headers( { name1 => 'value1, name2 => 'value2' } );

=item C<< B<< $self->cookie >> >>

The methods accepts a Perl hash of key => value pairs that will be used to add
an HTTP Cookie to the outgoing response (Magpie's base Output class figures
out whether you are using C<CGI.pm> or C<Apache::Request> and does the Right
Thing for you-- all you have to do is pass in a hash). Multiple calls to the
method add multiple cookies. Access to the list of outgoing cookies is
available through the C<< $self->cookies >> method.

Example:

  # set a cookie
  $self->cookie( -name    =>  'oreo',
                 -value   =>  'doublestuff',
                 -expires =>  '+3M');


=item C<< B<< $self->charset >> >>

The string passed to this method will set the outgoing character set header
for the current response.

Example:

  # set the outgoing character set header
  $self->charset('utf-8');

=item C<< B<< $self->mime_type >> >>

The string passed to this method will set the outgoing MIME type header for
the current response.

Example:

  # send the generated result as plain text
  $self->mime_type('text/plain');

=item C<< B<< $self->server_status >> >>

The numeric string passed to this method can be used to set the HTTP response
code for the current request. The value returned by this method will be the
status returned to interface module's call to $app_pipeline->run (where
$app_pipeline is an instance of Magpie::Machine). If you do not set this value
explicitly the default is C<200> which indicates that the process ran
normally.

Example:

  # stop the application pipeline and send a 404 error
  unless ( $ctxt->{some_file} && $other_condition ) {
      $self->server_status(404);
      return DONE;
  }

=back

In addition to the above built-in methods, Magpie Event classes provide a bit
of special convenience magic that allows you to create pipeline-wide accessor
methods merely by calling those methods on the $self class instance object.

Let's say for example that various event methods in the classes implemented in
your application pipeline depend upon having access to data in the same
database table. It would be wildly inefficient (not to mention silly) for each
of those classes to create an new connection to the database. To solve this--
and make sure that each class has access to the same data-- we can simply
store the database handle in the instance class of the first class that makes
the database connection:

  package MyClass::One;
  use DBI;

  sub event_init {
      my $self = shift;
      my $ctxt = shift;
      my $dbh = DBI->connect($data_source, $username, $auth, \%attr);
      $self->db_handle( $dbh );
      return OK;
  }

Now, any subsequent event handlers in that class B< or any class later in the
application pipeline > can access the database handle by simply calling
$self->db_handle

  package MyClass::Two; # runs in the pipeline after MyClass::One, above

  sub event_default {
      my $self = shift;
      my $ctxt = shift;

      # magically works because the upstream event handler
      # set a value for the db_handle method.
      my $sth = $self->db_handle->prepare( $some_sql );
      ...
      return OK;
  }

While this bit of magic is quite useful, the implementation shown here depends
on the fact that MyClass::One will run before MyClass::Two and for more
complex application pipelines this assumption might create problems. If you
wanted to make absolutely sure that every class in the application pipeline
has access to the database handle, irrespective of what any of the application
classes might (or might not) do, you can simply set the method on the
application pipeline instance.

  # sample2.pm -- A Typical Magpie application that sets a pipeline-wide
  # database accessor
  package sample2::handler;
  use Magpie::Machine;
  use Apache::Response;
  use Apache::Const;
  use DBI;


  sub handler {
      my $r = shift;

      # load the Application and Output classes into
      # the Magpie pipeline
      my $app = Magpie::Machine->new();

      $app->pipeline( qw(
          MyClass::One
          MyClass::Two
          Magpie::Output::Scalar
      ) );

      # now, create the DB handle and pass it to the instance
      # of the application pipeline
      my $dbh = DBI->connect($data_source, $username, $auth, \%attr);
      $app->db_handle( $dbh );

      # can be any type of Perl reference or object
      my $application_context = {};

      # execute the application pipeline
      return $app->run( $application_context );
  }

  1;

This done, the database handle is now predictably available to all event
methods in both MyClass::One and MyClass::Two via $self->db_handle .

=head3 Keeping Things In $ctxt

The second argument passed to each event handler method is the I<context
member> (named $ctxt in these examples). The context member-- which can be any
kind of Perl object or reference to another data structure-- is passed as the
sole argument to the application pipeline's run() method.

  # in your interface module/script:
  return $app->run( $application_context );

  ...

  # then later, in the event handler methods in your application classes
  sub event_myevent {
      my $self = shift;
      my $ctxt = shift; # same object/data as $application_context above
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

  return $app->run( \%context ); # note that this is a reference

  # pass in an empty, anonymous hash reference
  return $app->run( {} );

  # some advanced apps do well to make the context an object
  # that implements is own set of methods
  my $context = My::Application::ContextMember->new( %args );

  return $app->run( $context );


Obviously, the role of the context member will vary greatly depending upon
your coding style and the needs of the application. In general, though, the
most common use of the $ctxt is to accumulate the data needed to render the
proper output for the current request. For example, if you are using the
Template Toolkit Output class (Magpie::Output::TT2) you might use a plain hash
reference as the context member, then use it to capture the template name and
variables that your templates depend on to deliver the content.


=head2 Event Handler Return Codes

Each event handler method must return one of a number of I<event handler
return codes>. The codes signal Magpie's internal event loop about what to do
after the current event handler method is finished. The codes themselves are
numeric, but are implemented as convenient Perl constants via the
C<Magpie::Constants> module so you do not have to try to remember what the
numeric codes are (this is similar to the way the C<Apache::Constants> module
works for HTTP return codes).

 use Magpie::Constants;

 sub event_myevent {
     my $self = shift;
     my $ctxt = shift;

     # do a little dance...

     return OK;
 }

The most common return codes and their effects on the application's behavior are as follows

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

  sub event_init {
      my $self = shift;
      my $ctxt = shift;

      unless ( defined $ctxt->{some_required_data} ) {
          # we don't have the data we need to continue
          $ctxt->{error_message} = "Insufficient data for event_init";
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
pipeline are skipped, including the Output class. It is rarely used, given it
typically stops the application before any data is sent to the client, but it
can be useful for sending appropriate HTTP response codes.

  sub event_init {
      my $self = shift;
      my $ctxt = shift;

      unless ( -f $ctxt->{some_required_file} ) {
          # we don't have the some crucial file needed to proceed
          # so throw a 404 Not Found response while stopping the
          # application
          $self->server_status(404);
          return DONE;
      }

      # otherwise continue on...
      return OK;
  }


=back

With these details in mind let's look back at one of the event handler methods
from the C<My::Greetings> package:

  sub event_evening {
      my $self = shift;
      my $ctxt = shift;

      $ctxt->{message} = 'Good evening!';

      return OK;
  }


At its core, Magpie only implements a symbol table (for holding event
definitions) and an event queue (that fires and controls those events). The
conditions under which the events are fired is totally swappable.

=head1 Output Classes

=head2 XSLT (Magpie::Output::XML::LibXSLT)

=head2 Template Toolkit (Magpie::Output::TT2)

=head2 File (Magpie::Output::File)

=head2 Scalar (Magpie::Output::Scalar)


=head1 Application Pipelines

THIS SPACE FOR RENT

=head1 Why Magpie?

Consider the following (obviously rigged) example of a CGI user login script:

 # login.cgi
 use CGI;
 use Digest::MD5;

 my $query = CGI->new();

 my %args = $query->Vars;
 my %users = (); tie %users, 'MLDBM','users.mldbm', O_CREAT|O_RDWR, 0640
   or die "Can't open USERS file:$!\n";

 # Begin output
 print $query->header;
 print $query->start_html;

 if ( defined($args{username}) and defined($args{password}) ) {

     if ( defined($users{ $args{username}) {
         my $user = $args{username};
         # if we have a valid user...
         my $crypted = Digest::MD5::base_64($args{password});

         if ( $user{password} eq $crypted ) {
             # we have a valid user, proceed

         }
         else {
             # bad password
         }

     }
     else {
         #invalid user
     }
 }
 else {
   # missing username or password
 }

 print $query->end_html;

We have all seen (and probably written) scripts like this. On the one hand, it
is hard to say that this code is wrong, exactly. After all, it works-- it does
what we need it to do, and it didn't take very long to write. But from the
point of view of modern Web application development there are at least three
general weakness with this script.

First, there is no division between application logic and the content is that
generated for the client. Even if we do not need to support different types of
Web clients and can get away with just generating HTML for desktop browsers,
we run the risk of obscuring (or, worse, clobbering) the essential application
logic in order to tweak the visual output.

Second, and similarly, the application code and the logic that determines
application state are also inextricably mixed. Now, obviously. conditional
logic is likely to play a role in each state of any non-trivial application,
but it all too easy for scripts like the one above to become brambles of
if/else branches that obscure the application's essential functions.

Finally, code like that found in this script is the enemy of modularity and
re-use. A wise coder might wrap the block that checks for and verifies the
user's login cookie into a validate_user_cookie() function in a custom
application module that can be C<use>d or C<require>d into other scripts, but
knowing what code to pull out into a function is not always obvious, and fact
that such libs are usually not based on object oriented techniques make them
brittle and a likely dumping ground for ugly solutions and hard-coded
assumptions.

The point is that he script above will run, and for a certain set of
requesting clients, it will work as expected; but it will not cope with future
enhancements very well. For every additional case that the script has to
handle we are stuck adding yet another layer of state detection code and
hardcoded HTML output. By taking the "simple" approach, we have set a hard
limit on the amount of change and complexity that the application can cope
with. We have created a throw-away script that cannot grow or evolve without
becoming an unmaintainable mess.

Magpie offers a way to abstract away both the state-handling logic (how an
application determines what code to run under a given set of circumstances)
and the output mechanism (how the given application state is represented to
the requesting client) so that developers can devote their precious time to
unique behavior of the application. You simply define the states of your
application, and register events that will be executed when a given state is
encountered, and Magpie handles the rest.

By thinking about an application in terms of states we have a convenient,
unambiguous way to talk about and focus on the application's desired behavior
without muddying the discussion with implementation-specific details.
Similarly, by dividing an application into discrete states, we have a clear
roadmap for how to. We can say things like, "The application must not advance
past the validation state unless the user submitted a valid email address."
rather than "keep re-showing the input form unless the user submits a valid
email address".


=head1 References

=over

=item L<http://foldoc.doc.ic.ac.uk/foldoc/foldoc.cgi?finite+state+machine>

FOLDOC definition of Finite State Machines.

=back


1;
