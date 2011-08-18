package Magpie::Transformer::XSLT;
# ABSTRACT: XSLT Pipeline Transformer

use Moose;
extends 'Magpie::Transformer';
use Magpie::Constants;
use MooseX::Types::Path::Class;
use XML::LibXML;
use XML::LibXSLT;
use Try::Tiny;
use Scalar::Util ();
use Cwd ();
use Data::Dumper::Concise;

__PACKAGE__->register_events( qw(get_content transform));

sub load_queue { return qw( get_content transform ) }

has stylesheet_file => (
    is          => 'rw',
    isa         => 'Path::Class::File',
    init_arg    => 'stylesheet',
    writer      => 'stylesheet',
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

    my $xml_parser = XML::LibXML->new;
    if (my $upstream = $self->plack_response->body ) {
        if (ref $upstream) {
            $dom = $xml_parser->load_xml( IO => $upstream );
        }
        else {
            $dom = $xml_parser->load_xml( string => $upstream );
        }
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

    my $style = undef;
    my $xslt_processor = XML::LibXSLT->new;

    my $docroot = undef;

    if ( $self->has_resource && $self->resource->has_root ) {
        $docroot = $self->resource->root;
    }
    else {
        $docroot = Cwd::getcwd;
    }

    # we only want to touch URIs that may need munging to
    # resolve to a document root.
    my $match_cb = sub {
        my $uri = shift;
        # don't handle URI's supported by libxml
        return 0 if $uri =~ /^(https?|ftp|file):/;
        return 0 if $docroot && $uri =~ m|^\Q$docroot\E|;
        return 1;
    };

    my $open_cb = sub {
        my $uri = shift || './';
        if ($docroot) {
            unless ($uri =~ m|^\Q$docroot\E|) {
                $docroot .= '/' unless $docroot =~ m|/$|;
                $uri = $docroot . $uri;
            }
        }
        my $fh = IO::File->new($uri) || die "Error opening file $uri";
        local $/ = undef;
        my $data = <$fh>;
        return \$data;
    };

    my $read_cb = sub {
        my $string_ref = shift;
        my $length = shift;
        return substr($$string_ref, 0, $length, "");
    };

    my $icb = XML::LibXML::InputCallback->new();
    $icb->register_callbacks( [ $match_cb, $open_cb, $read_cb, sub {} ] );
    $xslt_processor->input_callbacks($icb);
    try {
        $style = $xslt_processor->parse_stylesheet_file( $self->stylesheet_file );
    }
    catch {
        warn "Error parsing stylesheet file: $_\n";
        $self->set_error({ status_code => 500, reason => $_ });
    };

    # remember that Try::Tiny won't return() the way you think it does
    return OK if $self->has_error;

    my $params = $self->request->parameters || {};

    my $result = undef;

    try {
        $result = $style->transform( $self->content_dom, XML::LibXSLT::xpath_to_string(%{$params}) );
    }
    catch {
        warn "Error applying stylesheet: $_\n";
        $self->set_error({ status_code => 500, reason => $_ });
    };

    return OK if $self->has_error;

    my $new_body     = $style->output_as_bytes( $result );
    my $content_type = $style->media_type;
    my $encoding     = $style->output_encoding;
    $self->response->content_type("$content_type; $encoding");
    $self->response->content_length( Plack::Util::content_length($new_body) );
    $self->response->body( $new_body );

    return OK;
}

# SEEALSO: Magpie, XML::LibXSLT

1;
