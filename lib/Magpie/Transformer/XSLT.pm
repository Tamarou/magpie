package Magpie::Transformer::XSLT;
use Moose;
extends 'Magpie::Component';
use Magpie::Constants;
use MooseX::Types::Path::Class;
use XML::LibXML;
use XML::LibXSLT;
use Try::Tiny;
use Data::Dumper::Concise;

__PACKAGE__->register_events( qw(get_content transform));

sub load_queue { return qw( get_content transform ) }

has stylesheet_file => (
    is          => 'ro',
    isa         => 'Path::Class::File',
    init_arg    => 'stylesheet',
    coerce      => 1,
    required    => 1,
);

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

has xslt_processor => (
    is          =>  'ro',
    isa         =>  'XML::LibXSLT',
    lazy_build  =>  1,
);

sub _build_xslt_processor {
    return XML::LibXSLT->new();
}

sub get_content {
    my $self = shift;
    my $ctxt = shift;

    my $dom = undef;

    # XXX make this work w/ dependency-aware Resource classes
    if (my $upstream = $self->plack_response->body ) {
        warn "UPSTREAM: $upstream\n";
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

    my $style = $self->xslt_processor->parse_stylesheet_file( $self->stylesheet_file );

    my $result = $style->transform( $self->content_dom );

    my $new_body     = $style->output_string( $result );
    my $content_type = $style->media_type;
    my $encoding     = $style->output_encoding;
    $self->response->content_type("$content_type; $encoding");
    $self->response->content_length( length($new_body) );
    $self->response->body( $new_body );

    return OK;
}

1;