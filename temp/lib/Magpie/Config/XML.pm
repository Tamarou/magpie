package Magpie::Config::XML;
use Moose;
use XML::LibXML;
use Data::Dumper::Concise;

sub process {
    my $self = shift;
    my $xml_file = shift;
    my @stack = ();
    my $dom = XML::LibXML->load_xml( location => $xml_file );
    my $root = $dom->documentElement;

    foreach my $pipe ($root->findnodes('//pipeline')) {
        foreach my $kid ($pipe->childNodes) {
            my $kid_name = $kid->localname;
            next unless $kid_name; # skip txt nodes here
            if ( $kid_name eq 'add' ) {

            }
            elsif ( $kid_name eq 'match' ) {
            warn Dumper( $kid );
        }
    }



    return @stack;
}

sub process_add {

}

1;
