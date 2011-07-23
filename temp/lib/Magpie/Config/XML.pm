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
        foreach my $pipe_child ($pipe->childNodes) {
            my $pipe_child_name = $pipe_child->localname;
            next unless $pipe_child_name; # skip txt nodes here
            if ( $pipe_child_name eq 'add' ) {
                process_add( $pipe_child );
            }
            elsif ( $pipe_child_name eq 'match' ) {
                warn Dumper( $pipe_child );
            }
            else {
                warn "Unknown child element '$pipe_child_name' in config.\n";
            }
        }
    }

    return @stack;
}

sub process_add {
    my $node = shift;
    my $class_name = $node->findvalue('@class|./class/text()');
    my $params = {};
    if ($node->exists('./parameters')) {
        foreach my $param ($node->findnodes('./parameters/*')) {
            warn Dumper( $param );
            my ($name, $value) = (undef, undef);
            if ($param->localname eq 'parameter' ) {
                $name = $param->findvalue('@name|./name/text()');
                $value = $param->findvalue('@value|./value/text()');
            }
            else {
                $name = $param->localname;
                $value = $param->findvalue('./text()');
                $params->{$name} = $value;
            }

            $value =~ s/^\s+//;
	        $value =~ s/\s+$//;

            if( $name && $value ) {
                $params->{$name} = $value;
            }
        }
    }

    return ($class_name, $params);
}

sub trim_whitespace {
    my $string = shift;

}

1;
