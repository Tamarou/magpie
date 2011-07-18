package Magpie::Transformer::XSP;
# ABSTRACT: eXtensible Server Pages Transformer

use Moose;
extends 'Magpie::Transformer';
use Magpie::Constants;
use MooseX::Types::Path::Class;
use XML::XSP;
use XML::LibXML;
use Try::Tiny;
#use Data::Dumper::Concise;
#BEGIN { $SIG{__DIE__} = sub { Carp::confess(@_) } }

__PACKAGE__->register_events( qw( get_content transform));

sub load_queue { return qw( get_content transform ) }

has content_dom => (
    is          => 'rw',
    isa         => 'XML::LibXML::Document',
);

has xml_parser => (
    is          => 'ro',
    isa         => 'XML::LibXML',
    lazy_build  => 1,
);

sub _build_xml_parser {
    return XML::LibXML->new();
}

has xsp_processor => (
    is          =>  'ro',
    isa         =>  'XML::XSP',
    lazy_build  =>  1,
);

sub _build_xsp_processor {
    return XML::XSP->new();
}

sub get_content {
    my $self = shift;
    my $ctxt = shift;

    my $dom = undef;

    # XXX make this work w/ dependency-aware Resource classes
    if (my $upstream = $self->plack_response->body ) {
        $dom = XML::LibXML->load_xml( IO => $upstream );
    }
    else {
        warn "Nothing UPSTREAM\n";
        $dom = XML::LibXML::Document->new();
    }

    $self->content_dom( $dom );
    return OK;
}

sub transform {
    my $self = shift;
    my $ctxt = shift;

    my $generated_package = undef;
    my $xsp = $self->xsp_processor;

    try {
        $generated_package = $xsp->process( $self->content_dom );
    }
    catch {
        warn "Error processing XSP source: $_\n";
        $self->set_error({ status_code => 500, reason => $_ });
    };

    # remember that Try::Tiny won't return() the way you think it does
    return OK if $self->has_error;

    try {
        eval "$generated_package";
    }
    catch {
        warn "Error compiling XSP source: $_\n";
        $self->set_error({ status_code => 500, reason => $_ });
    };

    return OK if $self->has_error;

    my $package_name = $xsp->package_name;
    my $instance = undef;

    try {
        $instance = $package_name->new;
    }
    catch {
        warn "Could not create an instance of the generated XSP class: $_\n";
        $self->set_error({ status_code => 500, reason => $_ });

    };

    return OK if $self->has_error;

    my $generated_dom = $instance->xml_generator($self->plack_request, XML::LibXML::Document->new, undef);

    my $new_body     = $generated_dom->toString;
    $self->response->content_length( length($new_body) );
    $self->response->body( $new_body );

    return OK;
}

# SEEALSO: Magpie, XML::XSP
1;