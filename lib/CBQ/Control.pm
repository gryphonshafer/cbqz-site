package CBQ::Control;

use exact -conf, 'Omniframe::Control';
use CBQ::Model::User;
use Mojo::File 'path';
use Omniframe::Util::File 'opath';
use Text::MultiMarkdown 'markdown';
use YAML::XS 'Load';

my $root_dir = conf->get( qw( config_app root_dir ) );
my $photos   = path( $root_dir . '/static/photos' )
    ->list_tree
    ->map( sub { substr( $_->to_string, length( $root_dir . '/static' ) ) } )
    ->grep(qr/\.(?:jpg|png)$/);

sub startup ($self) {
    $self->setup( skip => ['sockets'] );

    my $captcha_conf = conf->get('captcha');
    $captcha_conf->{ttf} = opath( $captcha_conf->{ttf} );
    $self->plugin( CaptchaPNG => $captcha_conf );

    my $static_paths = [ @{ $self->static->paths } ];
    my $regional_cms = conf->get('regional_cms');
    my $regions      = [
        map {
            $_->{acronym}  = lc $_->{acronym};
            $_->{path}     = path( join( '/', $root_dir, $regional_cms->{path_suffix}, $_->{acronym} ) );
            $_->{path_rel} = path( join( '/', $regional_cms->{path_suffix}, $_->{acronym} ) );
            $_->{settings} =
                ( -r $_->{path}->child( $regional_cms->{settings} ) )
                    ? Load( $_->{path}->child( $regional_cms->{settings} )->slurp )
                    : {};
            $_;
        } @{ CBQ::Model::User->dq->get(
            'region',
            [ qw( name acronym ) ],
            { active => 1 },
        )->run->all({})
    } ];

    my $redirects = {
        www => conf->get('redirects'),
        grep { defined } map {
            ( $_->{settings}{redirects} ) ? ( $_->{acronym} => $_->{settings}{redirects} ) : undef
        } @$regions,
    };

    my $docs_navs = {
        www => $self->docs_nav( @{ conf->get('docs') }{ qw( dir home_type home_name home_title ) } ),
        grep { defined } map {
            $_->{acronym} => $self->docs_nav(
                $_->{path_rel}->child('docs'),
                'md',
                uc( $_->{acronym} ) . ' Home',
                uc( $_->{acronym} ) . ' Christian Bible Quizzing Region',
            );
        } @$regions,
    };
    # push( @{ $docs_navs->{www} }, {
    #     href  => $self->url_for('/iq'),
    #     name  => '"Inside Quizzing"',
    #     title => 'The "Inside Quizzing" Podcast',
    # } );

    $self->hook( before_dispatch => sub ($c) {
        $c->app->sessions->cookie_domain(
            ( lc( $c->req->url->to_abs->host ) =~ /([^\.]+\.[^\.]+)$/ ) ? '.' . $1 : undef
        );

        my $subdomain = lc( ( split( /\./, $c->req->url->to_abs->host, 2 ) )[0] );
        my $pre_path  = lc( $c->req->url->path->parts->[0] // '' );
        my ($region)  = grep { $_->{acronym} eq $subdomain or $_->{acronym} eq $pre_path } @$regions;

        if (
            my $redirect = (
                $redirects->{ ($region) ? $region->{acronym} : 'www' } // {}
            )->{ $c->req->url->path }
        ) {
            $c->redirect_to($redirect);
        }
        elsif ($region) {
            unshift(
                @{ $c->app->static->paths },
                $region->{path}->child('static'),
            );
            if ( $region->{acronym} ne $subdomain and $region->{acronym} eq $pre_path ) {
                shift $c->req->url->path->parts->@*;
                $region->{pre_path} = 1;
            }
            $c->stash( region => $region );
        }
    } );
    $self->hook( before_routes => sub { $self->static->paths([@$static_paths]) } );

    $self->routes->add_condition( region => sub ( $route, $c, $captures, $value ) {
        return (
            $value and defined $c->stash->{region} or
            not $value and not defined $c->stash->{region}
        );
    });

    my $all = $self->routes->under( sub ($c) {
        $c->stash(
            page     => { wrappers => ['page_layout.html.tt'] },
            photos   => $photos->shuffle,
            docs_nav => $docs_navs->{ ( $c->stash('region') ) ? $c->stash('region')->{acronym} : 'www' },
            domain   => ( lc( $c->req->url->to_abs->host ) =~ /([^\.]+\.[^\.]+)$/ )
                ? $1
                : $c->req->url->to_abs->host_port,
        );

        if ( my $user_id = $c->session('user_id') ) {
            try {
                $c->stash( 'user' => CBQ::Model::User->new->load($user_id) );
            }
            catch ($e) {
                delete $c->session->{'user_id'};
                $c->notice( 'Failed user load based on session "user_id" value: "' . $user_id . '"' );
            }
        }

        return 1;
    } );

    my $users = $all->under( sub ($c) {
        return 1 if ( $c->stash('user') );
        $c->info('Login required but not yet met');
        $c->flash( memo => {
            class   => 'error',
            message => 'Login required for the previously requested resource.',
        } );
        $c->redirect_to('/user/login');
        return 0;
    } );

    $users->any( '/user/' . $_ )->to( 'user#' . $_ ) for ( qw( edit tools ) );
    $users->any( '/meeting/' . $_->[1] )->requires( region => 0 )->to( 'meeting#' . $_->[0] ) for (
        [ create      => 'create'                  ],
        [ vote_create => ':meeting_id/vote/create' ],
        [ vote        => ':meeting_id/vote'        ],
        [ close       => ':meeting_id/close'       ],
        [ view        => ':meeting_id'             ],
    );

    $all->any("/user/$_/:token")->to("user#$_") for ( qw( verify reset_password ) );
    $all->any( '/user/' . $_ )->to( 'user#' . $_ ) for ( qw(
        sign_up
        login
        forgot_password
        logout
    ) );
    $all->any('/')->requires( region => 0 )->to('main#index');
    # $all->any('/iq')->requires( region => 1 )->to('main#iq');
    $all->any( '/*name', { name => 'index.md' } )->to('main#content');
}

around 'tt_settings' => sub ( $orig, $self, @input ) {
    my $tt_settings = $orig->( $self, @input );

    $tt_settings->{config}{FILTERS}{markdownificate} = sub ($text) {
        $text =~ s/</&lt;/g;
        $text =~ s/>/&gt;/g;
        return markdown $text;
    };

    return $tt_settings;
};

1;

=head1 NAME

CBQ::Control

=head1 SYNOPSIS

    #!/usr/bin/env perl
    use MojoX::ConfigAppStart;
    MojoX::ConfigAppStart->start;

=head1 DESCRIPTION

This class is a subclass of L<Omniframe::Control> and provides an override to
the C<startup> method such that L<MojoX::ConfigAppStart> (along with its
required C<mojo_app_lib> configuration key) is sufficient to startup a basic
(and mostly useless) web application.

=head1 METHODS

=head2 startup

This is a basic, thin startup method for L<Mojolicious>. This method calls
C<setup> and sets a universal route that renders a basic text message.

=head2 tt_settings

This method wraps L<Omniframe::Role::Template>'s C<tt_settings> to inject a
C<markdownificate> L<Template::Plugin::Filter>.

=head1 INHERITANCE

L<Omniframe::Control>.
