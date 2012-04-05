package Magpie::Util;

# ABSTRACT: Common utility functions

#-------------------------------------------------------------------------------
# internal convenience for regularizing potentially uneven lists of name/param
# hash pairs
#-------------------------------------------------------------------------------
sub make_tuples {
    my @in = @_;
    my @out = ();
    for (my $i = 0; $i < scalar @in; $i++ ) {
        next if ref( $in[$i] ) eq 'HASH';
        my $args = {};
        if ( ref( $in[$i + 1 ]) eq 'HASH' ) {
            $args = $in[$i + 1 ];
        }
        push @out, [$in[$i], $args];
    }
    return @out;
}

1;
