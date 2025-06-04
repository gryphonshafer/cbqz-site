package CBQ::Control::Main;

use exact -conf, 'Mojolicious::Controller';
use Mojo::DOM;
use Mojo::File 'path';
use Omniframe::Class::Time;

sub index ($self) {
    $self->stash( title => conf->get( qw( docs home_title ) ) );
}

{
    my $docs_dir = conf->get( qw( docs dir ) );
    sub content ($self) {
        my $docs_path = (
            ( $self->stash->{req_info}{region} )
                ? $self->stash->{req_info}{region}{path} . '/'
                : ''
        ) . $docs_dir . '/';

        my $key = ( $self->stash->{req_info}{region} )
            ? $self->stash->{req_info}{region}{key}
            : undef;
        my $trailing_slash = $self->req->url->path->trailing_slash;
        my $hrefify        = sub ($href) {
            return unless ($href);
            return
                ( $href =~ m|^/|      ) ? '/' . $key . $href :
                ( not $trailing_slash ) ? $key . '/' . $href : undef;
        };

        $self->document(
            $docs_path . $self->stash('name'),
            sub ( $payload, $type ) {
                if (
                    ( $type eq 'md' or $type eq 'html' )
                    and $self->stash->{req_info}{region}
                    and not $self->stash->{req_info}{subdomain}
                ) {
                    $payload =~ s|(\[[^\]]*\]\s*\()([^\)]*)(\))| $1 . ( $hrefify->($2) // $2 ) . $3 |ge
                        if ( $type eq 'md' );

                    if ( $payload =~ /</ ) {
                        my $dom = Mojo::DOM->new($payload);
                        $dom->find('a')->each( sub {
                            if ( my $href = $hrefify->( $_->attr('href') ) ) {
                                $_->attr( href => $href );
                            }
                        } );
                        $payload = $dom->to_string;
                    }
                }
                return $payload;
            },
            $docs_path,
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

sub iq_rss ($self) {
    $self->res->headers->content_type('application/rss+xml; charset=UTF-8');
    $self->render(
        data => path( conf->get( qw( config_app root_dir ) ) )->child( conf->get('iq_rss') )->slurp('UTF-8'),
    );
}

sub season_schedule ($self) {
    my $now = time;

    my ($current_season) =
        sort { $a->{stop_time} <=> $b->{stop_time} }
        grep { $_->{start_time} <= $now and $_->{stop_time} >= $now }
        $self->stash->{req_info}{region}{settings}{seasons}->@*;

    ($current_season) =
        sort { $b->{start_time} <=> $b->{startp_time} }
        $self->stash->{req_info}{region}{settings}{seasons}->@*
            unless ($current_season);

    $self->stash(
        current_season => $current_season,
        now            => $now,
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

=head2 iq_rss

Handler for Inside Quizzing RSS feed.

=head2 season_schedule

Regional season schedule page.

=head1 INHERITANCE

L<Mojolicious::Controller>.
