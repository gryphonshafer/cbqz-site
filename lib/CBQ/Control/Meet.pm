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

{
    my $reg_conf = conf->get('registration');
    sub register ($self) {
        my ($current_next_meet) = grep { $_->{is_current_next_meet} } $self->_current_season->{meets}->@*;
        unless ( ( $self->stash('format') // '' ) eq 'json' ) {
            $self->stash(
                meet => $current_next_meet,
            );
        }
        else {
            $self->render( json => {
                reg => {
                    user => {
                        attend  => 0,
                        roles   => [],
                        drive   => 0,
                        housing => 1,
                        lunch   => 1,
                    },
                    notes => '',
                    orgs  => [
                        {
                            name    => 'Kitsap Bible Quizzing',
                            acronym => 'KIT',
                            teams   => [],
                        },
                        {
                            name    => 'Other Quizzing',
                            acronym => 'OQT',
                            teams   => [],
                        },
                    ],
                },
                meet      => $current_next_meet,
                roles     => $reg_conf->{roles},
                bibles    => $reg_conf->{bibles},
                user      => $self->stash('user')->data,
                user_edit => $self->url_for( $self->stash('path_part_prefix') . '/user/edit' ),
            } );
        }
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
