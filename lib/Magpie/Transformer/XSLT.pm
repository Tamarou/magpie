package Magpie::Transformer::XSLT;
# ABSTRACT: XSLT Pipeline Transformer

use Moose;
extends 'Magpie::Transformer';
use Magpie::Constants;
use MooseX::Types::Path::Class;
use XML::LibXML;
use XML::LibXSLT;
use Try::Tiny;
use Scalar::Util qw(blessed);
use Cwd ();
use File::Spec ();
use URI ();
use Carp qw(cluck);

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

has document_root => (
    is          => 'ro',
    isa         => 'Str',
    lazy_build  =>  1,
);

sub _build_document_root {
    my $self = shift;
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

    return Cwd::realpath($docroot);
}

sub absolute_path {
    my $self = shift;
    my $path = shift;
    my $docroot = $self->document_root;
    unless ($path =~ m|^\Q$docroot\E|) {
        $docroot .= '/' unless $docroot =~ m|/$| || $path =~ m|^/|;
        $path = $docroot . $path;
    }
    return $path;
}

our $WTF = 0;

use Data::Printer;

sub get_content {
    my $self = shift;
    my $ctxt = shift;
    warn "getting content '" . $self->response->status . "'";
    my $dom = undef;

    my $xml_parser = XML::LibXML->new( expand_xinclude => 1, huge => 1, debug => 1, recover => 1, no_xinclude_nodes => 1, no_basefix => 1 );

    my $docroot  = $self->document_root;
    my $resource = $self->resource;

    # we only want to touch URIs that may need munging to
    # resolve to a document root.
    my $match_cb = sub {
        my $uri_string = shift;
        my $uri = URI->new($uri_string, 'file');
        my $scheme = $uri->scheme;

        if ($resource && (!defined($scheme) || $scheme eq 'file') && -f $uri->path) {
            my @stat = stat($uri->path);
            my $mtime = @stat ? $stat[9] : -1;
            $resource->add_dependency($uri->path => { mtime => $mtime, size => $stat[7]});
        }
        # don't handle URI's supported by libxml
        return 0 if $uri_string =~ /^(https?|ftp|file):/;
        return 0 if $docroot && $uri_string =~ m|^\Q$docroot\E|;
        return 1;
    };

    my $open_cb = sub {
        my $uri = shift || './';
        unless ($uri =~ m|^\Q$docroot\E|) {
            $resource->delete_dependency($uri);
        }

        my $file_path = $self->absolute_path($uri);
        my $fh = IO::File->new($file_path) || die "Error opening file $uri ($file_path)";
        my @stat = stat($file_path);
        my $mtime = @stat ? $stat[9] : -1;
        # mtime + size, for Etags
        $resource->add_dependency($file_path => { mtime => $mtime, size => $stat[7]});

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

    my $upstream = $resource->data;
    #warn "upstream " . p($upstream);
    if ($upstream) {
        if (ref $upstream) {
            if (blessed($upstream)) {
                if ($upstream->isa('Plack::Util::IOWithPath')) {
                    try {
                        $dom = $xml_parser->load_xml( IO => $upstream );
                    }
                    catch {
                        warn "Error loading XML I/O: $_\n";
                        $self->set_error({ status_code => 500, reason => $_ });
                    };
                }
                elsif ($upstream->isa('XML::LibXML::Document')) {
                    $dom = $upstream;
                }
            }
        }
        else {
            try {
                $dom = $xml_parser->load_xml( string => $upstream );
            }
            catch {
                warn "Error loading XML string: $_\n";
                $self->set_error({ status_code => 500, reason => $_ });
            };

        }
    }
    else {
        $dom = XML::LibXML::Document->new();
    }

    return DECLINED if $self->has_error;

    $self->content_dom( $dom );
    $WTF++;
    return OK;
}

sub transform {
    my $self = shift;
    my $ctxt = shift;

    my $style = undef;
    my $xslt_processor = XML::LibXSLT->new;

    my $docroot = $self->document_root;

    # we only want to touch URIs that may need munging to
    # resolve to a document root.
    my $match_cb = sub {
        my $uri = shift;
        # don't handle URI's supported by libxml
        return 0 if $uri =~ /^(https?|ftp|file):/;
        return 1;
    };

    my $open_cb = sub {
        my $uri = shift || './';

        my $file_path = $self->absolute_path($uri);
        #warn "stylesheet open $uri";
        my $fh = IO::File->new($file_path) || die "Error opening file $uri ($file_path)";
        my @stat = stat($file_path);
        my $mtime = @stat ? $stat[9] : -1;
        # mtime + size, for Etags
        $self->resource->add_dependency($file_path => { mtime => $mtime, size => $stat[7]});
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

    my $stylesheet_file = $self->stylesheet_file;
    unless ($stylesheet_file =~ m|^\Q$docroot\E| || -f $stylesheet_file) {
        $stylesheet_file = $self->absolute_path($stylesheet_file);
    }


    try {
        $style = $xslt_processor->parse_stylesheet_file( $stylesheet_file );
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
    $self->response->content_type("$content_type; charset=$encoding");
    $self->response->content_length( length($new_body) );
    $self->resource->data( $new_body );

    return OK;
}

# SEEALSO: Magpie, XML::LibXSLT

1;
