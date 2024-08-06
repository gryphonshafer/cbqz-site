package CBQ::Control::Main;

use exact -conf, 'Mojolicious::Controller';
use GD::Image;
use Mojo::Asset::File;
use Mojo::DOM;
use Mojo::File 'path';
use Mojo::Util 'decode';
use Omniframe::Class::Time;
use Text::MultiMarkdown 'markdown';

sub index ($self) {
    $self->stash( title => conf->get( qw( docs home_title ) ) );
}

sub content ($self) {
    $self->document(
        conf->get( qw( docs dir ) ) . '/' . $self->stash('name'),
        undef,
        conf->get( qw( docs dir ) ) . '/',
    );
}

{
    my $time = Omniframe::Class::Time->new;
    sub _format_datetime( $datetime, $format = '%A, %B %e, %Y %l:%M:%S %p %Z' ) {
        return $time->parse($datetime)->format($format);
    }
}

sub iq ($self) {
    my $rss = Mojo::DOM->new(
        path( conf->get( qw( config_app root_dir ) ) )->child( conf->get('iq_rss') )->slurp
    );

    $self->stash(
        img_title    => $rss->at('channel > image > title')->text,
        img_src      => $rss->at('channel > image > url')->text,
        description  => $rss->at('channel > description')->text,
        last_updated => _format_datetime( $rss->at('channel > pubDate')->text ),
        items        => $rss->find('channel > item')->map( sub {
            my $dom  = $_;
            my $data = { map { $_ => $dom->at($_)->text } qw( title link description duration ) };

            $data->{pub_date} = _format_datetime( $dom->at('pubDate')->text, '%B %e, %Y %l %p %Z' );

            my $enclosure   = $dom->at('enclosure');
            $data->{type}   = $enclosure->attr('type');
            $data->{length} = int( $enclosure->attr('length') / 1024 / 1024 * 100 ) / 100;

            $data;
        } )->to_array,
    );
}

{
    my $captcha  = conf->get('captcha');
    my $root_dir = conf->get( qw( config_app root_dir ) );
    my $base     = path($root_dir);
    my ($ttf)    = glob( $base->to_string . '/' . $captcha->{ttf} );
    ($ttf)       = glob( $base->child( conf->get('omniframe') )->to_string . '/' . $captcha->{ttf} )
        unless ($ttf);

    sub captcha ($self) {
        srand;

        my $sequence = int( rand( 10_000_000 - 1_000_000 ) ) + 1_000_000;
        my $display  = $sequence;

        $display =~ s/^(\d{2})(\d{3})/$1-$2-/;
        $display =~ s/(.)/ $1/g;

        my $image  = GD::Image->new( $captcha->{width}, $captcha->{height} );
        my $rotate = rand() / $captcha->{rotation} * ( ( rand() > 0.5 ) ? 1 : -1 );

        $image->fill( 0, 0, $image->colorAllocate( map { eval $_ } $captcha->{background}->@* ) );
        $image->stringFT(
            $image->colorAllocate( map { eval $_ } $captcha->{text_color}->@* ),
            $ttf,
            $captcha->{size},
            $rotate,
            $captcha->{x},
            $captcha->{y_base} + $rotate * $captcha->{y_rotate},
            $display,
        );

        for ( 1 .. 10 ) {
            my $index = $image->colorAllocate( map { eval $_ } $captcha->{noise_color}->@* );
            $image->setPixel( rand( $captcha->{width} ), rand( $captcha->{width} ), $index )
                for ( 1 .. $captcha->{noise} );
        }

        $self->session( captcha => $sequence );
        return $self->render( data => $image->png(9), format => 'png' );
    }
}

1;

=head1 NAME

CBQ::Control::Main

=head1 DESCRIPTION

This class is a subclass of L<Mojolicious::Controller> and provides handlers
for "main" or general actions, including C<content> to feed documents.

=head1 METHODS

=head2 index

Handler for the home page of the web site.

=head2 content

Handler for everything under "/docs" served via the documents feeder.

=head2 iq

Handler for Inside Quizzing podcast page.

=head2 captcha

This handler will automatically generate and return a captcha image consisting
of a text sequence. That text sequence will also be added to the session under
the name C<captcha>.

=head1 INHERITANCE

L<Mojolicious::Controller>.
