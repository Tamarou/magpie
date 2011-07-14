use strict;
use warnings;
use Test::More;


use FindBin;
use lib "$FindBin::Bin/lib";
# use Plack::Test;
# use Plack::Builder;
# use Plack::Middleware::Magpie;
use Loader;
use Data::Printer;

my @wev = machine {
     match '/'       =>  [qw(RootMatch)];
#     match qr!/foo/! => ['Wibble'];
    match 'bar'     => (
        match 'internal' => ['INTENAL'],
        match 'internal2' => ['INTENAL2'],
        match 'crazytown' => (
            match 'deepinthewood' => ['WOAH']
        ),
    ),
    match 'wev' => (
        match 'seriously' => ['WhatEver']
    );
};

warn "returned " . p(@wev);
ok 1;

done_testing;
