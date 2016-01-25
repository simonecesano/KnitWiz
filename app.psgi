use strict;
use warnings;

use lib './lib';
use Plack::Builder;
use Plack::App::File;

use Mojo::Server::PSGI;

builder {
    my $server = Mojo::Server::PSGI->new;
    $server->load_app('./knitwiz.pl');
    $server->to_psgi_app;
}

