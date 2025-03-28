package CBQ::Control::Main;

use exact -conf, 'Mojolicious::Controller';
use Mojo::DOM;
use Mojo::File 'path';
use Omniframe::Class::Time;

sub index ($self) {
    $self->stash( title => conf->get( qw( docs home_title ) ) );
}

sub content ($self) {
    $self->document(
        conf->get( qw( docs dir ) ) . '/' . $self->stash('name'),
        undef,
        conf->get( qw( docs dir ) ) . '/',
    );

    if ( $self->res->code and $self->res->code == 404 ) {
        $self->stash( 'mojo.finished' => 0 );
        $self->flash( memo => {
            class   => 'error',
            message => 'Unable to find the resource previously requested. Redirected to home page.',
        } );
        $self->redirect_to('/');
    }
}

{
    my $time = Omniframe::Class::Time->new;
    sub _format_datetime( $datetime, $format = '%A, %B %e, %Y %l:%M:%S %p %Z' ) {
        return $time->parse($datetime)->format($format);
    }
}

sub iq ($self) {
    my $rss = Mojo::DOM->new(
        path( conf->get( qw( config_app root_dir ) ) )->child( conf->get('iq_rss') )->slurp('UTF-8')
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

=head1 INHERITANCE

L<Mojolicious::Controller>.
