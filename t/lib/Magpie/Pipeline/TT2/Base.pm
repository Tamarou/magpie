package Magpie::Pipeline::TT2::Base;
use Moose;
use Magpie::Constants;
extends 'Magpie::Component';

__PACKAGE__->register_events(qw(default complete));

sub load_queue {
    my ($self, $ctxt) = @_;
    my @events = ();
    if ( my $event = $self->request->param('appstate') ) {
        push @events, $event;
    }
    else {
        push @events, 'default';
    }
    return @events;
}

BEGIN { srand(time() ^ ($$ + ($$ << 15))) }

sub default {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{template} = 'prompt.tt2';
    $ctxt->{message} = 'Please complete the following form to generate your fabulous new movie star name';
    return OK;
}

sub complete {
    my $self    = shift;
    my $ctxt    = shift;

    my @param_names = $self->request->param;

    my @first_names = map { $self->request->param("$_") } grep { $_ =~ /^first_/ } @param_names;
    my @last_names  = map { $self->request->param("$_") } grep { $_ =~ /^last_/ }  @param_names;

    if ( ((scalar @first_names) + (scalar @last_names) != 6) || ( grep { length == 0 } @first_names, @last_names ) ) {
        $ctxt->{message} = 'All fields must be filled in. Please try again.';
        $ctxt->{template} = 'prompt.tt2';
        return OK;
    }

    $ctxt->{first_name} = $first_names[ int( rand( @first_names )) ];
    $ctxt->{last_name} = $last_names[ int( rand( @last_names )) ];
    $ctxt->{message} = 'Congratulations! Your Movie Star name has been magically determined!';
    $ctxt->{template} = 'complete.tt2';
    return OK;
}

1;
