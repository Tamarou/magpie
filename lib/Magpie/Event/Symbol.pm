package Magpie::Event::Symbol;
use Moose::Role;

#-------------------------------------------------------------------------------
# reset_symbol_handler( $symbol_name )
# Empties out the list of handler subs associated with $symbol_name in the
# symbol table.
#-------------------------------------------------------------------------------
sub reset_symbol_handler {
    my $self    = shift;
    my $symbol  = shift;

    if ( defined $symbol
         and length $symbol ) {
        if ( $self->symbol_table->has_symbol($symbol) ) {
            $self->symbol_table->reset_symbol($symbol);
        }
    }
    else {
        $self->symbol_table->reset_table;
    }
}

#-------------------------------------------------------------------------------
# add_symbol_handler( $symbol_name, $coderef )
# Adds the event sub ($coderef) to the entry in the symbol table associated
# with $symbol_name.
#-------------------------------------------------------------------------------
sub add_symbol_handler {
    my $self    = shift;
    my $symbol  = shift;
    my $handler = shift;

    $symbol = $self->_qualify_symbol_name( $symbol );

    unless ( defined $symbol and length $symbol and defined $handler and ref($handler) eq 'CODE' ) {
        die 'add_symbol_handler( $symbol_name => $coderef )';
    }

    return $self->symbol_table->add_symbol($symbol, $handler);
}


#-------------------------------------------------------------------------------
# get_symbol_handler( $symbol_name )
# Returns the list of handler subs associated with $symbol_name in the
# symbol table.
#-------------------------------------------------------------------------------

sub get_symbol_handler {
    my $self    = shift;
    my $symbol  = shift;

    $symbol = $self->_qualify_symbol_name( $symbol );

    if ( defined $symbol
         and length $symbol ) {
        if ( $self->symbol_table->has_symbol($symbol) ) {
            return @{$self->symbol_table->get_symbol($symbol)};
        }
    }

    warn("Unregistered Symbol: $symbol");
    return undef;
}

sub _qualify_symbol_name {
    my $self = shift;
    my $symbol = shift;
    return $symbol if $symbol =~ /\./;
    my $pkg = $self->meta->name;
    return $pkg . '.' . $symbol;
}

1;
