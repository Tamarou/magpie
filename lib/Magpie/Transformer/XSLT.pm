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
use URI ();
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

our $WTF = 0;

sub get_content {
    warn "GET CONTENT $WTF";
    my $self = shift;
    my $ctxt = shift;

    my $dom = undef;

    my $xml_parser = XML::LibXML->new( expand_xinclude => 1, huge => 1, debug => 1, recover => 1, no_xinclude_nodes => 1, no_basefix => 1 );

##
    my $docroot  = undef;
    my $resource = $self->resource;

    if ( $self->resource->can('has_root') && $self->resource->has_root ) {
        $docroot = $resource->root;
    }
    elsif ( defined $self->request->env->{DOCUMENT_ROOT} ) {
        $docroot = $self->request->env->{DOCUMENT_ROOT};
    }
    else {
        $docroot = Cwd::getcwd;
    }

    # we only want to touch URIs that may need munging to
    # resolve to a document root.
    my $match_cb = sub {
        my $uri_string = shift;
        warn "\n>>>>> MATCH $uri_string";
        my $uri = URI->new($uri_string, 'file');
        my $scheme = $uri->scheme;

        if ($resource && (!defined($scheme) || $scheme eq 'file') && -f $uri->path) {
            my @stat = stat($uri->path);
            my $mtime = @stat ? $stat[9] : -1;
            $resource->add_dependency($uri->path => $mtime . '-' . $stat[7]);
        }
        # don't handle URI's supported by libxml
        return 0 if $uri_string =~ /^(https?|ftp|file):/;
        return 0 if $docroot && $uri_string =~ m|^\Q$docroot\E|;
        return 1;
    };

    my $open_cb = sub {
        my $uri = shift || './';
        warn "OPEN $uri\n";
        if ($docroot) {
            unless ($uri =~ m|^\Q$docroot\E|) {
                if ($resource) {
                    $resource->delete_dependency($uri);
                }
                $docroot .= '/' unless $docroot =~ m|/$| || $uri =~ m|^/|;
                $uri = $docroot . $uri;
            }
        }

        my $fh = IO::File->new($uri) || die "Error opening file $uri";
        my @stat = stat($uri);
        my $mtime = @stat ? $stat[9] : -1;
        # mtime + size, for Etags
        $resource->add_dependency($uri => $mtime . '-' . $stat[7]);

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
    $xml_parser->input_callbacks($icb);
##

    if (my $upstream = $self->plack_response->body ) {
        if (ref $upstream) {
            try {
                $dom = $xml_parser->load_xml( IO => $upstream );
            }
            catch {
                warn "Error XML: $_\n";
                $self->set_error({ status_code => 500, reason => $_ });
            };

        }
        else {
            $dom = $xml_parser->load_xml( string => $upstream );
        }
    }
    else {
        warn "Nothing UPSTREAM\n";
        $dom = XML::LibXML::Document->new();
    }

    warn "DEPS " . Dumper( $resource->dependencies );
    $self->content_dom( $dom );
    $WTF++;
    return OK;
}

sub transform {
    my $self = shift;
    my $ctxt = shift;

    my $style = undef;
    my $xslt_processor = XML::LibXSLT->new;

    my $docroot = undef;

    if ( $self->resource->can('has_root') && $self->resource->has_root ) {
        $docroot = $self->resource->root;
    }
    elsif ( defined $self->request->env->{DOCUMENT_ROOT} ) {
        $docroot = $self->request->env->{DOCUMENT_ROOT};
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
    $self->response->content_length( length($new_body) );
    $self->response->body( $new_body );

    return OK;
}

# SEEALSO: Magpie, XML::LibXSLT

1;
