package Magpie::ConfigReader::XML;
use Moose;
use XML::LibXML;
use Data::Dumper::Concise;

sub make_token {
    return '__MTOKEN__XMLCONF';
}


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
            my ($match_type, $to_match, $input) = (undef, undef, []);
            if ( $pipe_child_name eq 'add' ) {
                $match_type = 'AUTO';
                push @{$input}, process_add( $pipe_child );
            }
            elsif ( $pipe_child_name eq 'match' ) {
                ($match_type, $to_match, $input) = process_match( $pipe_child );
            }
            else {
                warn "Unknown child element '$pipe_child_name' in config.\n";
            }
            push @stack, [$match_type, $to_match, $input, make_token];
        }
    }
    return @stack;
}

sub process_match {
    my $node = shift;
    my $input = [];
    my $match_type = $node->findvalue('@type|./type/text()');
    $match_type = uc $match_type;
    my $to_match = $node->findvalue('@rule|./rule/text()');
    if ( $match_type eq 'REGEXP' ) {
        $to_match = qr|$to_match|;
    }
    elsif ($match_type eq 'LITERAL' ) {
        $match_type = 'STRING';
    }
    elsif ($match_type eq 'ENV' ) {
        $match_type = 'HASH';
        $to_match = {};
        foreach my $rule ($node->findnodes('./rules/rule')) {
            my $key  = $rule->findvalue('@key|./key/text()');
            my $val  = $rule->findvalue('@value|./value/text()');
            my $type = $rule->findvalue('@type|./value/@type|./value/type/text()');
            if ( $type && $type eq 'regexp' ) {
                $val = qr|$val|;
            }
            next unless $key && $val;
            $to_match->{$key} = $val;
        }
    }

    foreach my $add ($node->findnodes('./add')) {
        push @{$input}, process_add( $add );
    }
    return ($match_type, $to_match, $input);
}

sub process_add {
    my $node = shift;
    my $class_name = $node->findvalue('@class|./class/text()');
    my $params = {};
    if ($node->exists('./parameters')) {
        foreach my $param ($node->findnodes('./parameters/*')) {
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
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

1;
