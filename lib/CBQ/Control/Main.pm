package CBQ::Control::Main;

use exact -conf, 'Mojolicious::Controller';
use Mojo::Asset::File;
use Mojo::Util 'decode';
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

=head1 INHERITANCE

L<Mojolicious::Controller>.
