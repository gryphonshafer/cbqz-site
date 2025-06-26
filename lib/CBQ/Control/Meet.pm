package CBQ::Control::Meet;

use exact -conf, 'Mojolicious::Controller';

use CBQ::Model::Region;
use CBQ::Model::Registration;
use CBQ::Model::Org;

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
            my $url_prefix = $self->url_for( $self->stash('path_part_prefix') );

            # TODO: load any previously saved registration data and merge it with orgs

            my $reg = {
                user => {
                    roles => $self->stash('user')->data->{info}{roles} // [],
                },
                orgs => [
                    map { +{
                        org_id      => $_->{org_id},
                        name        => $_->{name},
                        acronym     => $_->{acronym},
                        teams       => [],
                        nonquizzers => [],
                    } }
                    CBQ::Model::Org->new->every_data({
                        org_id => $self->stash('user')->org_and_region_ids->{orgs},
                    })->@*
                ],
            };

            $self->render( json => {
                reg    => $reg,
                meet   => $current_next_meet,
                roles  => $reg_conf->{roles},
                bibles => $reg_conf->{bibles},
                urls   => {
                    user_edit => $url_prefix . '/user/edit',
                    meet_data => $url_prefix . '/meet/data',
                },
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
