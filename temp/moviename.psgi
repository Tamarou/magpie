#/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../t/lib";

use Plack::Builder;
use Plack::Middleware::Magpie;

my $app = builder {
    enable "Magpie", context => {}, pipeline => [
        'Magpie::Pipeline::TT2::Base',
        'Magpie::Pipeline::TT2::Output' => { template_path => './t/htdocs/templates/moviename' }
    ];
};