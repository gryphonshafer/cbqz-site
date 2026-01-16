package CBQ::Control::Main;

use exact -conf, 'Mojolicious::Controller';
use CBQ::Model::Region;
use DBD::SQLite::Constants 'SQLITE_OPEN_READONLY';
use Mojo::DOM;
use Mojo::File qw( path tempfile );
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
                ( $self->stash('req_info')->{domain} ? '//' . $self->stash('req_info')->{domain} : '' ) .
                '/' . $href
                if ( $href =~ s|^\*/|| );
            return if ( $self->stash->{req_info}{subdomain} );
            return
                ( $href =~ m|^/| ) ? '/' . $key . $href :
                ($trailing_slash)  ? $key . '/' . $href : undef;
        };

        $self->document(
            $docs_path . $self->stash('name'),
            sub ( $payload, $type ) {
                if (
                    ( $type eq 'md' or $type eq 'html' )
                    and $self->stash->{req_info}{region}
                ) {
                    $payload =~ s|(\[[^\]]*\]\s*\()([^\)]*)(\))| $1 . ( $hrefify->($2) // $2 ) . $3 |ge
                        if ( $type eq 'md' );

                    if ( $payload =~ /</ ) {
                        my $dom = Mojo::DOM->new($payload);

                        for my $tag (
                            [ qw( a href ) ],
                            [ qw( img src ) ],
                        ) {
                            $dom->find( $tag->[0] )->each( sub {
                                my $target = $hrefify->( $_->attr( $tag->[1] ) );
                                $_->attr( $tag->[1] => $target ) if ($target);
                            } );
                        }

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

sub cms_update ($self) {
    my $result = CBQ::Model::Region->new->cms_update({
        key    => $self->param('key')    || 1,
        secret => $self->param('secret') || 1,
        app    => $self->app,
    });

    $self->render(
        status => ( ( $result->{success} ) ? 200 : 400 ),
        json   => $result,
    );
}

sub rules_change ($self) {
    my @fields = qw(
        current_rule
        desired_rule_change
        roi
        tenents_and_architecture
        hard_cases
        taxonomy_level
        steelman
    );

    $self->stash( $self->req->params->to_hash->%* );
    my $fields_filled = grep { length( $self->param($_) ) } @fields;

    if ( $fields_filled > 0 ) {
        if ( $fields_filled != @fields ) {
            $self->stash( memo => {
                class   => 'error',
                message => 'Submitted form was incomplete.',
            } );
        }
        else {
            Omniframe::Class::Email->new( type => 'rules_change' )->send({
                to   => conf->get( qw( email from ) ),
                data => $self->req->params->to_hash,
            });

            $self->flash( memo => {
                class   => 'success',
                message => 'Form submitted successfully.',
            } );
            $self->redirect_to('/');
        }
    }
}

sub order_lms ($self) {
    my ( $method, $format ) = ( $self->req->method, $self->stash('format') );
    my $order_lms = conf->get('order_lms');

    if ( $method eq 'GET' and $format and $format eq 'json' ) {
        $self->render( json => $order_lms );
    }
    elsif ( $method eq 'POST' and my $order = $self->req->json ) {
        Omniframe::Class::Email->new( type => 'order_lms' )->send({
            to   => join( ', ', $order_lms->{email}->@* ),
            data => $order,
        });

        $self->render( json => {
            class   => 'success',
            message => 'Lesser Magistrate (LM) order submitted successfully.',
        } );
    }
}

sub download ($self) {
    try{
        my $dbh  = $self->stash('user')->dq->clone({ sqlite_open_flags => SQLITE_OPEN_READONLY });
        my $temp = tempfile( SUFFIX => '.sqlite' );

        $dbh->sqlite_backup_to_file($temp);
        $dbh->disconnect;

        $self->res->headers->content_type('application/x-sqlite');
        $self->res->headers->content_disposition(
            'attachment; filename="' . path( $dbh->{Name} )->basename . '"'
        );
        $self->res->body( $temp->slurp );
        $self->rendered;
    }
    catch ($e) {
        $self->notice( 'Download database error: ' . $e );
        $self->flash(
            memo => {
                class   => 'error',
                message => 'There was a problem preparing or downloading the database',
            },
        );
        $self->redirect_to('/user/tools');
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

=head2 iq_rss

Handler for Inside Quizzing RSS feed.

=head2 cms_update

Webhook to update regional CMS content. Requires "key" (a region's acronym) and
"secret" parameters. Returns result as JSON.

=head2 rules_change

Handler for rule change proposal submissions.

=head2 order_lms

Handler for ordering Lesser Magistrates.

=head2 download

Handler to download the application database.

=head1 INHERITANCE

L<Mojolicious::Controller>.
