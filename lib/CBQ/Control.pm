package CBQ::Control;

use exact -conf, 'Omniframe::Control';
use CBQ::Model::Region;
use CBQ::Model::User;
use Mojo::File 'path';
use Omniframe::Util::File 'opath';
use Text::MultiMarkdown 'markdown';

sub startup ($self) {
    my $root_dir = conf->get( qw( config_app root_dir ) );
    my $photos   = path( $root_dir . '/static/photos' )
        ->list_tree
        ->map( sub { substr( $_->to_string, length( $root_dir . '/static' ) ) } )
        ->grep(qr/\.(?:jpg|png)$/);

    my $iq_rss               = conf->get('iq_rss');
    my $regions_nav_position = conf->get( qw( regional_cms nav_position ) );
    my $region_obj           = CBQ::Model::Region->new;
    my $regions              = $region_obj->all_settings_processed;
    my $yaml_errors          = [ @{ $region_obj->yaml_errors } ];
    my $redirects            = {
        www => conf->get('redirects'),
        grep { defined }
        map {
            ( $regions->{$_}{settings} and $regions->{$_}{settings}{redirects} )
                ? ( $_ => $regions->{$_}{settings}{redirects} )
                : undef
        }
        keys %$regions,
    };

    $self->setup( skip => ['sockets'] );

    my $captcha_conf = conf->get('captcha');
    $captcha_conf->{ttf} = opath( $captcha_conf->{ttf} );
    $self->plugin( CaptchaPNG => $captcha_conf );

    my $static_paths = [ @{ $self->static->paths } ];
    my $www_docs_nav = $self->docs_nav( @{ conf->get('docs') }{ qw( dir home_type home_name home_title ) } );

    my $quizsage_nav_node = {
        href  => 'https://quizsage.org',
        name  => 'QuizSage',
        title => 'QuizSage Bible Quizzing Software',
    };

    if ( defined $regions_nav_position and $regions and %$regions ) {
        splice( @$www_docs_nav, $regions_nav_position, 0, {
            folder => 'Regions',
            nodes  => [
                map {
                    +{
                        href      => '/' . $_,
                        subdomain => $_,
                        name      => ( $regions->{$_}{name} // uc($_) ),
                        title     => uc($_) .
                            ( ( $regions->{$_}{name} ) ? ' - ' . $regions->{$_}{name} : '' ),
                    };
                }
                sort keys %$regions,
            ],
        } );

        my ($cbq_system) = grep { $_->{folder} and $_->{folder} eq 'CBQ System' } @$www_docs_nav;
        push( $cbq_system->{nodes}->@*, $quizsage_nav_node ) if ($cbq_system);
    }

    push( @$www_docs_nav, {
        href  => '/iq',
        name  => '"Inside Quizzing"',
        title => 'The "Inside Quizzing" Podcast',
    } ) if ($iq_rss);

    my $docs_navs = {
        www => $www_docs_nav,
        map {
            my $docs_nav = $self->docs_nav(
                $regions->{$_}{path}->child('docs'),
                'md',
                ( $regions->{$_}{name} // uc($_) ) . ' CBQ Region',
                (
                    ( $regions->{$_}{name} )
                        ? $regions->{$_}{name} . ' (' . uc($_) . ')'
                        : uc($_)
                ) . ' Christian Bible Quizzing (CBQ) Region',
            );

            splice( @$docs_nav, 1, 0, {
                folder => 'Meets and Rules',
                nodes  => [
                    {
                        href  => '/meet/schedule',
                        name  => 'Season Schedule',
                        title => q{Current Season's Meet Schedule},
                    },
                    {
                        href  => '*/rules',
                        name  => 'Rule Book',
                        title => 'Rule Book for Christian Bible Quizzing (CBQ)',
                    },
                    $quizsage_nav_node,
                ],
            } );

            $_ => $docs_nav;
        }
        keys %$regions,
    };

    $self->hook( before_dispatch => sub ($c) {
        lc( $c->req->url->to_abs->host_port ) =~ /(?:(?<subdomain>[^\.]+)\.)?(?<domain>[^\.]+\.[^\.]+)$/;
        my $req_info = {%+};

        $req_info->{regions} = $regions;

        $req_info->{subdomain} = lc( $req_info->{subdomain} // '' );
        if ( $req_info->{subdomain} ) {
            if ( exists $regions->{ $req_info->{subdomain} } ) {
                $req_info->{region} = $regions->{ $req_info->{subdomain} };
            }
            else {
                my ($region_key) =
                    grep {
                        grep { $_ eq $req_info->{subdomain} } $regions->{$_}{settings}{alternate_names}->@*
                    }
                    keys %$regions;
                if ($region_key) {
                    $req_info->{region} = $regions->{$region_key};

                    my $redirect = $c->req->url->to_abs->clone;
                    $redirect->host( $region_key . '.' . lc( $req_info->{domain} ) );
                    $c->redirect_to($redirect);
                }
            }
        }
        $req_info->{region} //= $regions->{ lc( $c->req->url->path->parts->[0] // '' ) };
        if ( $req_info->{subdomain} and not $req_info->{region} ) {
            my $redirect = $c->req->url->to_abs->clone;
            $redirect->host( lc( $req_info->{domain} ) );
            $c->redirect_to($redirect);
        }

        $req_info->{path_part} = (
            $req_info->{region} and
            not $regions->{ $req_info->{subdomain} // '' }
        ) ? 1 : 0;

        ( $req_info->{domain_sans_port} = $req_info->{domain} ) =~ s/:\d+$// if ( $req_info->{domain} );
        $c->app->sessions->cookie_domain(
            ( $req_info->{domain_sans_port} ) ? '.' . $req_info->{domain_sans_port} : undef
        );

        shift @{ $c->req->url->path->parts } if ( $req_info->{region} and $req_info->{path_part} );

        if (
            my $redirect = (
                $redirects->{ ( $req_info->{region} ) ? $req_info->{region}{key} : 'www' } // {}
            )->{ $c->req->url->path->clone->trailing_slash(0) }
        ) {
            $c->redirect_to($redirect);
        }
        elsif ( $req_info->{region} ) {
            unshift(
                @{ $c->app->static->paths },
                $req_info->{region}{path}->child('static'),
            );
        }

        $c->stash(
            yaml_errors      => $yaml_errors,
            req_info         => $req_info,
            path_part_prefix => ( $req_info->{region} and $req_info->{path_part} )
                ? (
                    '../' x (
                        scalar( $c->req->url->path->parts->@* ) +
                        ( ( $c->req->url->path->trailing_slash ) ? 1 : 0 )
                    )
                ) . $req_info->{region}{key}
                : '',
        );
    } );
    $self->hook( before_routes => sub { $self->static->paths([@$static_paths]) } );

    $self->routes->add_condition( region => sub ( $route, $c, $captures, $value ) {
        return (
            $value and defined $c->stash->{req_info}{region} or
            not $value and not defined $c->stash->{req_info}{region}
        );
    });

    my $all = $self->routes->under( sub ($c) {
        $c->stash(
            page     => { wrappers => ['page_layout.html.tt'] },
            photos   => $photos->shuffle,
            iq_rss   => $iq_rss,
            docs_nav => $docs_navs->{
                ( $c->stash->{req_info}{region} )
                    ? $c->stash->{req_info}{region}{key}
                    : 'www'
            },
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

    $users->any( '/user/' . $_ )->to( 'user#' . $_ ) for ( qw( edit tools list ) );
    $users->any('/user/view/:user_id')->to('user#view');
    $users->any( '/user/' . $_ )->to( 'user#' . $_ ) for ( qw( become unbecome ) );
    $users->any( '/meeting/' . $_->[1] )->requires( region => 0 )->to( 'meeting#' . $_->[0] ) for (
        [ list        => 'list'                    ],
        [ create      => 'create'                  ],
        [ vote_create => ':meeting_id/vote/create' ],
        [ vote_delete => ':meeting_id/vote/delete' ],
        [ vote        => ':meeting_id/vote'        ],
        [ unvote      => ':meeting_id/unvote'      ],
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

    $users->any('/org/list')->to('org#list');
    $users->any('/org/view/:org_id')->to('org#view');
    $users->any('/org/create')->requires( region => 1 )->to('org#crud');
    $users->any('/org/edit/:org_id')->to('org#crud');

    $all->any('/meet/schedule')->requires( region => 1 )->to('meet#schedule');

    $users
        ->any( '/meet/register' => [ format => ['json'] ] )
        ->requires( region => 1 )
        ->to( 'meet#register', format => undef );

    $users
        ->any( '/meet/data' => [ format => [ qw( csv json ) ] ] )
        ->requires( region => 1 )
        ->to( 'meet#data', format => undef );

    $users->any('/download')->to('main#download');

    if ($iq_rss) {
        $all->any('/iq')->requires( region => 0 )->to('main#iq');
        $all->any('/iq.rss')->requires( region => 0 )->to('main#iq_rss');
    }

    $all->any('/update')->to('main#cms_update');
    $all->any('/rules_change')->to('main#rules_change');
    $all
        ->any( '/order_lms' => [ format => ['json'] ] )
        ->to( 'main#order_lms', format => undef );

    $all->any('/')->requires( region => 0 )->to('main#index');
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
