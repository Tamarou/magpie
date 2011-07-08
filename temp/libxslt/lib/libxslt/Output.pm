package libxslt::Output;
use strict;
use warnings;
use XML::LibXML;
use SAWA::Constants;
use SAWA::Output::XML::LibXSLT;
our @ISA = qw/ SAWA::Output::XML::LibXSLT /;

sub get_stylesheet {
    my $self = shift;
    my $ctxt = shift;

    # this is more complest than it usually would be
    # due to the fact that the test dir may be installed 
    # in any dir
    my $style_path = $self->static_path . '/styles/moviename/';

#     if ($ENV{MOD_PERL}) {
#         $style_path = $self->query->r->document_root;
#         $style_path .= '/styles/moviename/';
#     }
#     else {
#         require Cwd;
#         $style_path = Cwd::abs_path('../htdocs/styles/moviename');
#         $style_path .= '/';
#     }

    $self->stylesheet(  $style_path . $ctxt->{stylesheet} );
    return OK;
}
    
sub get_document {
    my $self = shift;
    my $ctxt = shift;
    my $dom  = XML::LibXML::Document->new();
    my $root = $dom->createElement( 'application' );
    $dom->setDocumentElement( $root );

    foreach my $token ( qw( message first_name last_name ) ) {
        if ( defined( $ctxt->{ $token } )) {
            my $element = $dom->createElement( $token );
            $element->appendChild( $dom->createTextNode( $ctxt->{ $token } ) );
            $root->appendChild( $element );
        }
    }

    $self->document( $dom );
    return OK;
}

sub get_style_params {
    # just copy all params through (should this be the default?)
    my $self = shift;
    my $ctxt = shift;
    my %style_params = ();
    
    for ( $self->query->param ) {
        $style_params{$_} = $self->query->param($_);
    }

    $self->style_params( \%style_params );
    return OK;
}

1;
