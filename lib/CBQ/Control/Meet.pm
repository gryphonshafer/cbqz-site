package CBQ::Control::Meet;

use exact -conf, 'Mojolicious::Controller';

use CBQ::Model::Region;
use CBQ::Model::Registration;

sub _current_season ($self) {
    return CBQ::Model::Region->new->current_season(
        $self->stash->{req_info}{region}{settings}{seasons}
    );
}

sub schedule ($self) {
    $self->stash( current_season => $self->_current_season );
}

sub register ($self) {
    my ($current_next_meet) = grep { $_->{is_current_next_meet} } $self->_current_season->{meets}->@*;
    unless ( ( $self->stash('format') // '' ) eq 'json' ) {
        $self->stash(
            meet => $current_next_meet,
        );
    }
    else {
        $self->render( json => {
            attend => 0,
            meet   => $current_next_meet,
            roles  => conf->get( qw( registration roles ) ),
        } );
    }
}

1;

=head1 NAME

CBQ::Control::Meet

=head1 DESCRIPTION

This class is a subclass of L<Mojolicious::Controller> and provides handlers
for "meet" actions.

=head1 METHODS

=head2 schedule

Regional season schedule page.

=head2 register

Handler for meet registration.

=head1 INHERITANCE

L<Mojolicious::Controller>.
