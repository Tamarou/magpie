# Magpie - A RESTful Web Framework for Perl5

Magpie is a web framework for Perl5 that steals the shiny bits from many different web frameworks we at Tamarou have used over the last decade. It is based on the ideas expressed by the W3C TAG in [Architecture of the World Wide Web][1], namely that the web is comprised of Resources that respond to certain methods (GET, POST, PUT, DELETE etc). 

Obviously Magpie is a work in progress, as such there is very little documentation currently (patches welcome), and there may be bugs lurking in dark corners. However we have successfully been using it for paid work for over a year now so we're willing to bet our reputations on it.

## Getting Started

Magpie is a Dist::Zilla based distribution and is not yet on CPAN. To install Magpie you can either checkout the repo and go through the standard dzil setup: `dzil authordeps | cpanm; dzil listdeps | cpanm;` or we have provided an early-look release to make playing with magpie easier. To install the early-look release just run `cpanm http://xrl.us/magpie120650` or if you don't have cpanm installed `curl -L http://cpanmin.us | perl - http://xrl.us/magpie120650`.

We are currently working on an [demo application][2] that we hope will really show off some of the basic concepts in Magpie nice. We hope to release more examples and demo applications as time allows.

## Getting Help

Magpie has a channel on `irc.perl.org`, `#magpie`. You are welcome to come there and ask questions. We haven't yet gotten around to setting up a mailing list, but you're welcome to email either of the authors or contact us in the usual ways.

## Who is this we?

We are the guys behind [Tamarou](http://tamarou.com), a small consulting shop. We've been doing web application for a decade, and consulting for rather less than that.

[1]: http://www.w3.org/TR/2004/REC-webarch-20041215/
[2]: https://github.com/Tamarou/Firebrand
