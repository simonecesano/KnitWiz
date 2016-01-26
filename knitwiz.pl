#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojolicious::Static;
use Mojo::JSON qw(decode_json encode_json);
use Digest::MD5 qw(md5 md5_hex);
use Text::MultiMarkdown 'markdown';

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

# push @{$static->paths}, './temp';

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
    my ($act_w, $act_h) = ( $pdf_w / (150 / 2.56), $pdf_h / (150 / 2.56) );
    $c->stash(bbox => \@bbox, act_w => $act_w, act_h => $act_h, md5 => $md5 );
    $c->render(template => '/rasterize/params');
};

post '/r/:md5/view' => sub {
    my $c = shift;
    my $md5 = $c->param('md5');

    my $file = './temp/' . $md5 . '.pdf';
    my $png = './temp/' . $md5 . '.png';

    unless (-e $png) {
	my @bbox = split /\s+/, [ grep { /\%\%BoundingBox:/ } split /\n|\r/, qx/gs -o nul -sDEVICE=bbox "$file" 2>&1 / ]->[0] =~ s/%%BoundingBox: //r;
	my $pdf_w = $bbox[2] - $bbox[0];
	my $pdf_h = $bbox[3] - $bbox[1];
	
	my ($act_w, $act_h) = ($c->param('width'), $c->param('height'));
	my ($den_w, $den_h) = ($c->param('loops_h'), $c->param('loops_v'));
	
	my ($png_w, $png_h) = ($act_w * $den_w, $act_h * $den_h);
	my ($dpi_x, $dpi_y) = ($png_w / $pdf_w * 72, $png_h / $pdf_h * 72);
	
	my $resample = join 'x', map { $_ *= 1 } ($dpi_x, $dpi_y);
	
	app->log->info(qq/pdftoppm -rx $dpi_x -ry $dpi_y -aaVector no -png "$file" | convert - -trim png:- > "$png"/);
	app->log->info(qx/pdftoppm -rx $dpi_x -ry $dpi_y -aaVector no -png "$file" | convert - -trim png:- > "$png"/);
    }

    my $id = qx/identify -verbose "$png"/;
    $c->res->headers->content_type('text/plain');
    $c->render(text => $id);
};

get '/r/:md5/view' => sub {
    my $c = shift;
    my $md5 = $c->param('md5');
    my $png = './temp/' . $md5 . '.png';
    
    my $id = qx/identify -verbose "$png"/;
    for ($id) {
	s/:\n/" => {\n/g;
	s/: /" => "/g;
	s/\n/",\n/mg;
	s/^(.)/{\n$1/;
	s/(.)$/$1\n}\n/;
	s/\n(\s+)(.)/\n$1"$2/g;
    }
    $c->res->headers->content_type('text/plain');
    $c->render(text => $id);
};    

get '/r/:md5/image' => sub {
    my $c = shift;
    my $md5 = $c->param('md5');
    my $static = Mojolicious::Static->new( paths => [ 'temp' ] );
    $static->serve($c, $md5 . '.png');
    $c->rendered;
};

get '/r/:md5/finish' => sub {
    my $c = shift;
    $c->render(text => '/r/:project/finish');
};

app->start;

__DATA__
