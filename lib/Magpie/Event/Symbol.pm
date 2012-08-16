package Magpie::Event::Symbol;

# ABSTRACT: Role implementing the common symbol table interface.
use Moose::Role;

requires qw(default_symbol_table);

has symbol_table => (
    is      => 'rw',
    isa     => 'Magpie::SymbolTable',
    builder => 'default_symbol_table',
    handles  => [qw(has_symbol reset_symbol reset_table add_symbol get_symbol)],
);

#-------------------------------------------------------------------------------
# reset_symbol_handler( $symbol_name )
# Empties out the list of handler subs associated with $symbol_name in the
# symbol table.
#-------------------------------------------------------------------------------
sub reset_symbol_handler {
    my $self   = shift;
    my $symbol = shift;

    if ( defined $symbol
        and length $symbol )
    {
        if ( $self->has_symbol($symbol) ) {
            $self->reset_symbol($symbol);
        }
    }
    else {
        $self->reset_table;
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

    $symbol = $self->_qualify_symbol_name($symbol);

    unless (defined $symbol
        and length $symbol
        and defined $handler
        and ref($handler) eq 'CODE' )
    {
        die 'add_symbol_handler( $symbol_name => $coderef )';
    }

    return $self->add_symbol( $symbol, $handler );
}

#-------------------------------------------------------------------------------
# get_symbol_handler( $symbol_name )
# Returns the list of handler subs associated with $symbol_name in the
# symbol table.
#-------------------------------------------------------------------------------

sub get_symbol_handler {
    my $self   = shift;
    my $symbol = shift;

    $symbol = $self->_qualify_symbol_name($symbol);

    if ( defined $symbol
        and length $symbol )
    {
        if ( $self->has_symbol($symbol) ) {
            return @{ $self->get_symbol($symbol) };
        }
    }

    warn("Unregistered Symbol: $symbol");
    return undef;
}

sub _qualify_symbol_name {
    my $self   = shift;
    my $symbol = shift;
    return $symbol if $symbol =~ /\./;
    my $pkg = $self->meta->name;
    return $pkg . '.' . $symbol;
}

# SEEALSO: Magpie, Magpie::SymbolTable

1;
