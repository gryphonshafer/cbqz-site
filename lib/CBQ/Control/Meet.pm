package CBQ::Control::Meet;

use exact -conf, 'Mojolicious::Controller';
use CBQ::Model::Region;
use CBQ::Model::Registration;
use Text::CSV_XS 'csv';
use Mojo::Util 'slugify';

sub _current_season ($self) {
    return CBQ::Model::Region->new->current_season(
        $self->stash->{req_info}{region}{settings}{seasons}
    );
}

sub _current_next_meet ($self) {
    my ($current_next_meet) = grep { $_->{is_current_next_meet} } $self->_current_season->{meets}->@*;
    return $current_next_meet;
}

sub schedule ($self) {
    $self->stash( current_season => $self->_current_season );
}

{
    my $reg_conf = conf->get('registration');
    sub register ($self) {
        my ( $method, $format ) = ( $self->req->method, $self->stash('format') );
        my $current_next_meet = $self->_current_next_meet if ($method eq 'GET');

        if ( $method eq 'GET' and not $format ) {
            $self->stash( meet => $current_next_meet );
        }
        elsif ( $method eq 'GET' and $format eq 'json' ) {
            my $url_prefix = $self->url_for( $self->stash('path_part_prefix') );

            $self->render( json => {
                reg => CBQ::Model::Registration->new->get_reg(
                    $self->stash('req_info')->{region}{id},
                    $self->stash('user'),
                ),
                meet   => $current_next_meet,
                roles  => $reg_conf->{roles},
                bibles => $reg_conf->{bibles},
                urls   => {
                    user_edit => $url_prefix . '/user/edit',
                    meet_data => $url_prefix . '/meet/data',
                },
            } );
        }
        elsif ( $method eq 'POST' and my $reg = $self->req->json ) {
            if ( $current_next_meet->{registration_closed} ) {
                $self->render( json => {
                    class   => 'error',
                    message => 'Meet registration closed.',
                } );
            }
            else {
                my $authorized_org_ids   = $self->stash('user')->org_and_region_ids->{orgs};
                my $submitted_orgs_count = $reg->{orgs}->@*;
                $reg->{orgs}             = [
                    grep {
                        my $org = $_;
                        grep { $org->{org_id} == $_ } @$authorized_org_ids;
                    } $reg->{orgs}->@*
                ];

                CBQ::Model::Registration->new->create( {
                    user_id   => $self->stash('user')->id,
                    region_id => $self->stash('req_info')->{region}{id},
                    info      => $reg,
                } );

                $self->render( json => {
                    class   => 'success',
                    message => 'Meet registration data saved.' . (
                        ( $submitted_orgs_count != $reg->{orgs}->@* )
                            ? '.. but not all team organizations were authorized.'
                            : ''
                    ),
                } );
            }
        }
        else {
            $self->stash( memo => {
                class   => 'error',
                message => 'Unexpected condition in rendering the registration page.',
            } );
        }
    }
}

sub data ($self) {
    my $data = {
        reg_data => CBQ::Model::Registration->new->get_data( $self->stash('req_info')->{region}{id} ),
        meet     => $self->_current_next_meet,
    };

    unless ( $self->stash('format') ) {
        $self->stash(%$data);
    }
    elsif ( $self->stash('format') eq 'json' ) {
        $self->render( json => $data );
    }
    elsif ( $self->stash('format') eq 'csv' ) {
        csv( out => \my $csv, in => [
            [
                qw( Organization Acronym Team Name Bible M/F Rookie ),
                ( $data->{meet}{host}{housing} ? 'Housing' : undef ),
                ( $data->{meet}{host}{lunch} ? 'Lunch' : undef ),
                'Notes',
            ],

            (
                map {
                    my $org_name   = $_->{name};
                    my $acronym    = $_->{acronym};
                    my $team_count = 0;

                    map {
                        my $team = $acronym . ' ' . ++$team_count;
                        map {
                            [ grep { defined }
                                $org_name,
                                $acronym,
                                $team,
                                $_->{name},
                                $_->{bible},
                                $_->{m_f},
                                $_->{rookie},
                                ( $data->{meet}{host}{housing} ? $_->{housing} : undef ),
                                ( $data->{meet}{host}{lunch} ? $_->{lunch} : undef ),
                                '',
                            ];
                        } @$_;
                    }
                    $_->{teams}->@*;
                }
                $data->{reg_data}{orgs}->@*
            ),

            (
                map {
                    [ grep { defined }
                        join( ', ', map { $_->{name} } $_->{info}{orgs}->@* ),
                        join( ', ', map { $_->{acronym} } $_->{info}{orgs}->@* ),
                        '',
                        $_->{name},
                        '',
                        '',
                        '',
                        ( $data->{meet}{host}{housing} ? $_->{info}{user}{housing} : undef ),
                        ( $data->{meet}{host}{lunch} ? $_->{info}{user}{lunch} : undef ),
                        ( $_->{info}{notes} // '' ),
                    ];
                } $data->{reg_data}{registrants}->@*
            ),

            (
                map {
                    my $org_name = $_->{name};
                    my $acronym  = $_->{acronym};
                    map {
                        [ grep { defined }
                            $org_name,
                            $acronym,
                            '',
                            $_->{name},
                            '',
                            '',
                            '',
                            ( $data->{meet}{host}{housing} ? $_->{housing} : undef ),
                            ( $data->{meet}{host}{lunch} ? $_->{lunch} : undef ),
                            '',
                        ];
                    }
                    $_->{nonquizzers}->@*;
                }
                $data->{reg_data}{orgs}->@*
            ),
        ] );

        ( my $filename = lc $data->{meet}{name} ) =~ s/<[^>]*>//g;
        chomp $filename;
        $filename = join( '_',
            substr( $data->{meet}{start}, 0, 10 ),
            slugify($filename),
            'meet_registration_data.csv',
        );

        $self->res->headers->content_type('text/csv; charset=utf-8');
        $self->res->headers->content_disposition(qq{attachment; filename="$filename"});
        $self->render( data => $csv );
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

=head2 data

Handler for meet data.

=head1 INHERITANCE

L<Mojolicious::Controller>.
