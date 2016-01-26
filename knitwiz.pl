#!/usr/bin/env perl
use Mojolicious::Lite;
use Digest::MD5 qw(md5 md5_hex);

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

get '/' => sub {
  my $c = shift;
  $c->render(template => 'index');
};

get '/login' => sub {
    my $c = shift;
    $c->render(text => '/login');
};

get '/r/upload' => sub {
    my $c = shift;
    $c->render(template => '/rasterize/upload');
};

post '/r/upload' => sub {
    my $c = shift;
    my $file = $c->param('file');
    app->log->info($file->filename);
    my $md5 = Digest::MD5->new;
    $md5->add($file->slurp);
    $c->render(text => join '', '/r/', $md5->hexdigest, '/params');
};

get '/r/:md5/params' => sub {
    my $c = shift;
    $c->render(template => '/rasterize/params');
};

get '/r/:md5/view' => sub {
    my $c = shift;
    $c->render(text => '/r/:project/view');
};

get '/r/:md5/finish' => sub {
    my $c = shift;
    $c->render(text => '/r/:project/finish');
};

__DATA__

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<h1>Welcome to the Mojolicious real-time web framework!</h1>
To learn more, you can browse through the documentation
<%= link_to 'here' => '/perldoc' %>.
