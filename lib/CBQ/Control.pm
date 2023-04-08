package CBQ::Control;

use exact -conf, 'Omniframe::Control';

my $root_dir = conf->get( qw( config_app root_dir ) );
my $photos   = Mojo::File
    ->new( $root_dir . '/static/photos' )
    ->list_tree
    ->map( sub { substr( $_->to_string, length( $root_dir . '/static' ) ) } )
    ->grep(qr/\.(?:jpg|png)$/);

sub startup ($self) {
    $self->setup;

    my $all = $self->routes->under( sub ($self) {
        $self->stash(
            docs_nav => $self->docs_nav( @{ conf->get('docs') }{ qw( dir home_type home_name home_title ) } ),
            page     => { wrappers => ['page_layout.html.tt'] },
            photos   => $photos->shuffle,
        );
    } );

    $all->any('/')     ->to('main#index');
    $all->any('/*name')->to('main#content');
}

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

=head1 INHERITANCE

L<Omniframe::Control>.
