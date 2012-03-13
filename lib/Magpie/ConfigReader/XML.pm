package Magpie::ConfigReader::XML;
#ABSTRACT: Magpie Configuration via XML

use Moose;
use XML::LibXML;
use Data::Dumper::Concise;

sub make_token {
    return '__MTOKEN__XMLCONF';
}

has match_stack => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[ArrayRef]',
    default => sub { [] },
    handles => {
        push_stack => 'push',
    },
);

has assets => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[Object]',
    default => sub { [] },
    handles => {
        add_asset => 'push',
    },
);

has accept_matrix => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[ArrayRef]',
    default => sub { [] },
    handles => {
        add_variant => 'push',
    },
);

sub process {
    #warn "process config";
    my $self = shift;
    my $xml_file = shift;

    my $dom = XML::LibXML->load_xml( location => $xml_file );
    my $root = $dom->documentElement;

    if ( $root->exists('//accept_matrix')) {
        $self->process_accept_matrix( $root->findnodes('//accept_matrix') );
    }

    if ( $root->exists('//assets')) {
        $self->process_assets( $root->findnodes('//assets') );
    }

    # now process the handler pipeline
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
            $self->push_stack( [$match_type, $to_match, $input, make_token] );
        }
    }
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
    elsif ($match_type eq 'ACCEPT' ) {
        $to_match = $node->findvalue('@variant_name|./variant_name/text()');
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

sub process_accept_matrix {
    my $self = shift;
    my $node = shift;
    foreach my $variant ($node->findnodes('./variant')) {
        my $name = $variant->findvalue('@name|./name/text()');
        next unless length $name;
        my ($type, $lang, $qs, $encoding, $charset, $length);

        if ($variant->exists('@type|./type')) {
            $type = $variant->findvalue('@type|./type/text()');
        }

        if ($variant->exists('@language|./language|@lang|./lang')) {
            $lang = $variant->findvalue('@language|./language/text()|@lang|./lang/text()');
        }

        if ($variant->exists('@qs|./qs')) {
            $qs = $variant->findvalue('@qs|./qs/text()');
        }

        if ($variant->exists('@encoding|./encoding')) {
            $encoding = $variant->findvalue('@encoding|./encoding/text()');
        }

        if ($variant->exists('@charset|./charset')) {
            $charset = $variant->findvalue('@charset|./charset/text()');
        }

        if ($variant->exists('@length|./length')) {
            $length = $variant->findvalue('@length|./length/text()');
        }
        $self->add_variant([$name, $qs, $type, $encoding, $charset, $lang, $length]);
    }
}

sub process_assets {
    Class::MOP::load_class('Bread::Board');
    my $self = shift;
    my $node = shift;
    foreach my $container ($node->findnodes('./container')) {
        #warn "Container";
        $self->process_asset_container($container);
    }

    foreach my $service ($node->findnodes('./service')) {
        #warn "Service";
        $self->process_asset_service($service);
    }
}

sub process_asset_container {
    my ($self, $node, $parent) = @_;
    my $name = $node->findvalue('@name|./name/text()') || '';
    my $c = Bread::Board::Container->new( name => $name );
    if (defined $parent) {
        $parent->add_sub_container($c);
    }
    else {
        $self->add_asset($c);
    }

    foreach my $service ($node->findnodes('./service')) {
        $self->process_asset_service($service, $c);
    }
}

sub process_asset_service {
    my ($self, $node, $container) = @_;
    
    my %service_args = (
        name => $node->findvalue('@name|./name/text()'),
    );

    my $injector_type = $node->findvalue('@type|./type/text()');

    $injector_type ||= 'literal';
    my $s;
    
    if ($injector_type eq 'literal') {
        $service_args{value} = $node->findvalue('@value|./value/text()|./text()');
        $s = Bread::Board::Literal->new(%service_args);
    }
    
    if (defined $container) {
        $container->add_service($s);
    }
    else {
        $self->add_asset($s);
    }
}

# SEEALSO: Magpie

1;
