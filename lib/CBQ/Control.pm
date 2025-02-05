package CBQ::Control;

use exact -conf, 'Omniframe::Control';
use CBQ::Model::User;
use Mojo::File 'path';
use Omniframe::Util::File 'opath';
use Text::MultiMarkdown 'markdown';

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

    my $docs_nav = $self->docs_nav( @{ conf->get('docs') }{ qw( dir home_type home_name home_title ) } );

    push( @$docs_nav, {
        href  => $self->url_for('/iq'),
        name  => '"Inside Quizzing"',
        title => 'The "Inside Quizzing" Podcast',
    } );

    my $all = $self->routes->under( sub ($c) {
        $c->stash(
            docs_nav => $docs_nav,
            page     => { wrappers => ['page_layout.html.tt'] },
            photos   => $photos->shuffle,
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
        $c->flash( message => 'Login required for the previously requested resource.' );
        $c->redirect_to('/user/login');
        return 0;
    } );

    $users->any( '/user/' . $_ )->to( 'user#' . $_ ) for ( qw( edit tools ) );

    $users->any('/meeting/create')                 ->to('meeting#create');
    $users->any('/meeting/:meeting_id/vote/create')->to('meeting#vote_create');
    $users->any('/meeting/:meeting_id/vote')       ->to('meeting#vote');
    $users->any('/meeting/:meeting_id/close')      ->to('meeting#close');
    $users->any('/meeting/:meeting_id')            ->to('meeting#view');

    $all->any('/')  ->to('main#index');
    $all->any('/iq')->to('main#iq');

    $all->any("/user/$_/:user_id/:user_hash")->to("user#$_") for ( qw( verify reset_password ) );
    $all->any( '/user/' . $_ )->to( 'user#' . $_ ) for ( qw(
        sign_up
        login
        forgot_password
        logout
    ) );

    for my $redirect (
        [ '/rules'   => '/CBQ_system/rule_book.md' ],
        [ '/ioc'     => '/international_open_championships.md' ],
        [ '/ioc2025' => '/international_open_championships.md' ],
    ) {
        $all->any( $redirect->[0] => sub ($c) { $c->redirect_to( $redirect->[1] ) } );
    }

    $all->any('/*name')->to('main#content');
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
