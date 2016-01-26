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
    $md5 = $md5->hexdigest;
    $file->move_to('./temp/' . $md5 . '.pdf');
    $c->render(text => join '', '/r/', $md5, '/params');
};

get '/r/:md5/params' => sub {
    my $c = shift;
    my $md5 = $c->param('md5');
    my $file = './temp/' . $md5 . '.pdf';
    #------------------------------------------------
    my @bbox = split /\s+/, [ grep { /\%\%BoundingBox:/ } split /\n|\r/, qx/gs -o nul -sDEVICE=bbox "$file" 2>&1 / ]->[0] =~ s/%%BoundingBox: //r;
    my $pdf_w = $bbox[2] - $bbox[0];
    my $pdf_h = $bbox[3] - $bbox[1];
    #------------------------------------------------
    app->log->info(join ', ', @bbox);
    $c->stash(bbox => \@bbox, pdf_w => $pdf_w, pdf_h => $pdf_h );
    $c->render(template => '/rasterize/params');
};

post '/r/:md5/params' => sub {
    my $c = shift;
    $c->render(json => $c->req->params);
};


get '/r/:md5/view' => sub {
    my $c = shift;
    $c->render(text => '/r/:project/view');
};

get '/r/:md5/finish' => sub {
    my $c = shift;
    $c->render(text => '/r/:project/finish');
};

app->start;

__DATA__
