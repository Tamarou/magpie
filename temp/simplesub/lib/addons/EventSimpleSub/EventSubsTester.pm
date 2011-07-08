package addons::EventSimpleSub::EventSubsTester;
use strict;
use warnings;
use SAWA::Constants;
use Data::Dumper;
use SAWA::Event::SimpleSub;
use vars qw(@ISA);
@ISA = qw(SAWA::Event::SimpleSub);

sub registerEvents {
return qw ( one two three );
}

sub matchEvents {
    my $self = shift;
    my $ctxt = shift;
    my @events = ();
    my $state = $self->query->param('as');

    return () unless defined $state;
    push @events, 'one'   if $state =~ /one/;
    push @events, 'two'   if $state =~ /two/;       
    push @events, 'three' if $state =~ /three/;    

    return @events;
}

sub event_init {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} = 'EST1::INIT...';
    return OK;
}

sub event_default {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= 'EST1::DEFAULT...';
    return OK;
}

sub event_one {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= 'EST1::ONE...';
    return OK;
}

sub event_two {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= 'EST1::TWO...';
    return OK;
}

sub event_three {
    my $self = shift;
    my $ctxt = shift;
    $ctxt->{content} .= 'EST1::THREE...';
    return OK;
}

1;
