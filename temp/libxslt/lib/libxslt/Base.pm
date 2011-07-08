package libxslt::Base;
use SAWA::Constants;
use SAWA::Event::Simple;
use strict;
our @ISA = qw( SAWA::Event::Simple );

BEGIN { srand(time() ^ ($$ + ($$ << 15))) }

sub registerEvents {
    return qw/ complete /;
}

sub event_default {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{stylesheet} = 'prompt.xsl';
    $ctxt->{message} = 'Please complete the following form to generate your fabulous new movie star name';
    return OK;
}

sub event_complete {
    my $self    = shift;
    my $ctxt    = shift;

    my @param_names = $self->query->param;
   
    my @first_names = map { $self->query->param("$_") } grep { $_ =~ /^first\./ } @param_names;
    my @last_names  = map { $self->query->param("$_") } grep { $_ =~ /^last\./ }  @param_names;

    if ( ((scalar @first_names) + (scalar @last_names) != 6) || ( grep { length == 0 } @first_names, @last_names ) ) {
        $ctxt->{message} = 'All fields must be filled in. Please try again.';
        $ctxt->{stylesheet} = 'prompt.xsl';
        return OK;
    }

    $ctxt->{first_name} = $first_names[ int( rand( @first_names )) ];
    $ctxt->{last_name} = $last_names[ int( rand( @last_names )) ];
    $ctxt->{message} = 'Congratulations! Your Movie Star name has been magically determined!';
    $ctxt->{stylesheet} = 'complete.xsl';
    return OK;
}

1;
