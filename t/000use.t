use Test::More;
use File::Find;

my @classes = ();

my $skipped = 0;

my @optional = (qw(
    Magpie::ConfigReader::XML
));

my $root = -e 'blib/' ? 'blib/lib' : 'lib';

File::Find::find(
    sub {
        return unless $_ =~ /.pm$/;
        my $path = $File::Find::name;
        $path =~ s|^$root/||;
        $path =~ s|.pm$||;
        $path =~ s|/|::|g;
        return if $path =~ /::(Resource|Transformer|Plugin)::/;
        push @classes, $path;
    },
    $root
);


ok( scalar( @classes ) > 0 );

foreach my $class ( @classes ) {
    if (grep { $_ eq $class } @optional) {
        $skipped++;
        next;
    }
    use_ok( $class );
}

done_testing( (scalar( @classes ) + 1) - $skipped );
