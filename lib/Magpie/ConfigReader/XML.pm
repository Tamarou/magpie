package Magpie::ConfigReader::XML;
#ABSTRACT: Magpie Configuration via XML

use Moose;
use XML::LibXML;
use Magpie::Util;
use Magpie::Plugin::URITemplate;
use Class::Load;

#use Data::Printer;

sub make_token {
    return '__MTOKEN__XMLCONF';
}

sub make_match_token {
    return '__MATCH__' . int( rand(100000) );
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
                #push @{$input}, $self->process_match( $pipe_child );
                $self->process_match( $pipe_child );
                next;
            }
            else {
                warn "Unknown child element '$pipe_child_name' in config.\n";
            }
            $self->push_stack( [$match_type, $to_match, $input, make_token, make_match_token] );
        }

    }

}

sub process_match {
    my $self = shift;
    my $node = shift;
    my @input = ();
    my $match_type = $node->findvalue('@type|./type/text()');
    $match_type = uc $match_type;
    my $to_match = $node->findvalue('@rule|./rule/text()');

    foreach my $child ($node->childNodes) {
        my $name = $child->localname;
        next unless $name && length $name;
        if ($name eq 'add') {
            push @input, process_add($child);
        }
        elsif ($name eq 'match') {
            push @input, $self->process_match($child);
        }
        elsif ($name eq 'reset') {
            push @input, '__RESET__';
        }
    }

    if ( $match_type eq 'REGEXP' ) {
        $to_match = qr|$to_match|;
    }
    elsif ($match_type eq 'LITERAL') {
        $match_type = 'STRING';
    }
    elsif ($match_type eq 'ENV') {
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
    elsif ($match_type eq 'ACCEPT') {
        $to_match = $node->findvalue('@variant_name|./variant_name/text()');
    }
    # NOTE: See comment in Plack::Middleware::Magpie re: this munging.
    elsif ($match_type eq 'TEMPLATE') {
        $match_type = 'REGEXP';
        my $uri_template = $to_match;

        # to_match becomes the compiled regexp here
        my ($match_re, $names) = Magpie::Plugin::URITemplate::process_template($to_match);
        $to_match = $match_re;
        my @parameterized = ();
        for (my $i = 0; $i < scalar @input; $i++ ) {
            next if ref( $input[$i] ) eq 'HASH';
            if ($input[$i] =~/__MATCH__/) {
                push @parameterized, $input[$i];
                next;
            }

            my $args = {};
            if ( ref( $input[$i + 1 ]) eq 'HASH' ) {
                $args = $input[$i + 1 ];
            }

            if (defined $args->{traits}) {
                if (ref $args->{traits} eq 'ARRAY') {
                    push @{$args->{traits}}, '+Magpie::Plugin::URITemplate';
                }
                else {
                    my $existing = delete $args->{traits};
                    $args->{traits} = [$existing, '+Magpie::Plugin::URITemplate'];
                }
            }
            else {
                $args->{traits} = ['+Magpie::Plugin::URITemplate'];
            }

            $args->{uri_template} = $uri_template;
            push @parameterized, ($input[$i], $args);
        }
        @input = @parameterized;
    }

    my $match_token = make_match_token;
    $self->push_stack( [$match_type, $to_match, \@input, make_token, $match_token] );
    return $match_token;
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
            }

            $value =~ s/^\s+//;
	        $value =~ s/\s+$//;


            if( $name && $value ) {
                if (defined $params->{$name}) {
                    if (ref ($params->{$name}) eq 'ARRAY') {
                        push @{$params->{$name}}, $value;
                    }
                    else {
                        my $existing = delete $params->{$name};
                        $params->{$name} = [$existing, $value];
                    }
                }
                else {
                    $params->{$name} = $value;
                }
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
    Class::Load::load_class('Bread::Board');
    my $self = shift;
    my $node = shift;
    foreach my $container ($node->findnodes('./container')) {
        $self->process_asset_container($container);
    }

    foreach my $service ($node->findnodes('./service')) {
        $self->process_asset_service($service);
    }

    foreach my $alias ($node->findnodes('./alias')) {
        my $name = $alias->findvalue('@name|./name/text()');
        my $path = $alias->findvalue('@path|./path/text()');
        my $service_alias = Bread::Board::Service::Alias->new(
            name                => $name,
            aliased_from_path   => $path,
        );
        $self->add_asset($service_alias)
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

    foreach my $child ($node->findnodes('./container')) {
        $self->process_asset_container($child, $c);
    }

    foreach my $service ($node->findnodes('./service')) {
        $self->process_asset_service($service, $c);
    }

    foreach my $alias ($node->findnodes('./alias')) {
        my $name = $alias->findvalue('@name|./name/text()');
        my $path = $alias->findvalue('@path|./path/text()');
        my $service_alias = Bread::Board::Service::Alias->new(
            name                => $name,
            aliased_from_path   => $path,
        );
        $c->add_service($service_alias)
    }

}

sub process_asset_service {
    my ($self, $node, $container) = @_;

    my %service_args = (
        name => $node->findvalue('@name|./name/text()'),
    );

    if ($node->exists('@class|./class')) {
        $service_args{class} = $node->findvalue('@class|./class/text()');
    }

    my $injector_type = $node->findvalue('@type|./type/text()');

    $injector_type ||= 'literal';
    my $injector_subclass;

    if ($injector_type eq 'literal') {
        $injector_subclass = 'Bread::Board::Literal';
        $service_args{value} = $node->findvalue('@value|./value/text()|./text()');
    }
    elsif ($injector_type eq 'constructor') {
        $injector_subclass = 'Bread::Board::ConstructorInjection';
    }
    elsif ($injector_type eq 'setter') {
        $injector_subclass = 'Bread::Board::SetterInjection';
    }
    elsif ($injector_type eq 'block') {
        $injector_subclass = 'Bread::Board::BlockInjection';
        my %deps = ();

        if ($node->exists('@class|./class')) {
            my $dep = $node->findvalue('@class|./class/text()');
            $deps{$dep} = 1;
        }

        foreach my $classnode ($node->findnodes('./requires/class')) {
            my $dep = $classnode->findvalue('.');
            $deps{$dep} = 1;
        }

        my $dep_string = join "\n", map { "use $_;" } keys %deps;

        my $block = $node->findvalue('./block/text()');
        my $pkg_name = random_string();
        my $subname  = random_string();
        my $full_name = $pkg_name . '::' . $subname;
        my $pkg = 'package ' . $pkg_name .'; ' . $dep_string . ' sub ' . $subname . '{' . $block . '} 1;';

        eval "$pkg";
        $service_args{block} = \&$full_name;
    }

    if ($node->exists('@lifecycle|./lifecycle')) {
            $service_args{lifecycle} = $node->findvalue('@lifecycle|./lifecycle');
    }

    if ($node->exists('./dependencies')) {
        my $deps = {};
        foreach my $d ($node->findnodes('./dependencies/dependency')) {
            my $dep_type = $d->findvalue('@type|./type/text()');
            if ($dep_type && $dep_type eq 'literal') {
                my $dep_name = $d->findvalue('@name|./name/text()');
                my $dep_val  = $d->findvalue('@value|./value/text()');
                my $dep_key  = $d->findvalue('@key|./key/text()') || $dep_name;
                $deps->{$dep_key} = Bread::Board::Literal->new( name => $dep_name, value => $dep_val);
            }
            else {
                my $dep_name = $d->findvalue('@name|./name/text()');
                my $dep_path = $d->findvalue('@service_path|./service_path/text()');
                $deps->{$dep_name} = Bread::Board::Dependency->new( service_path => $dep_path );
            }
        }

        $service_args{dependencies} = $deps;
    }

    my $s = $injector_subclass->new(%service_args);

    if (defined $container) {
        $container->add_service($s);
    }
    else {
        $self->add_asset($s);
    }
}

sub random_string {
    my $length = shift || 10;
    my $ret = '';
    my @chars = ('a'..'z', 'A'..'Z');
    for (0..$length) {
        $ret .= $chars[ rand @chars ];
    }
    return $ret;
}
# SEEALSO: Magpie

1;
