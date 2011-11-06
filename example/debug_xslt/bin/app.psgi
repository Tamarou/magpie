#!/usr/bin/perl
use strict;
use warnings;
use FindBin;

use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../../lib";

use Plack::Builder;


my $docroot = "$FindBin::Bin/../root";

my $app = builder {
    #enable 'Debug', panels => [ qw(Memory Timer TrackObjects Environment) ];
    enable "Magpie",
        resource => { class => 'Magpie::Resource::File', root => $docroot},
        pipeline => [
            'Magpie::Transformer::XSLT' => { stylesheet  => "/stylesheets/default.xsl" },
        ];
};

$app;
