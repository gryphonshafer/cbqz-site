package CBQ::Control::Meet;

use exact -conf, 'Mojolicious::Controller';
use CBQ::Model::Region;
use CBQ::Model::Registration;
use Text::CSV_XS 'csv';
use Mojo::Util 'slugify';

sub _current_season ( $self, $time = undef ) {
    return CBQ::Model::Region->new->current_season(
        $self->stash->{req_info}{region}{settings}{seasons},
        $time,
    );
}

sub _current_next_meet ( $self, $time = undef ) {
    my ($current_next_meet) = grep { $_->{is_current_next_meet} } $self->_current_season($time)->{meets}->@*;
    return $current_next_meet;
}

sub schedule ($self) {
    my $current_season = $self->_current_season;

    if (
        not $current_season or
        ref $current_season->{meets} ne 'ARRAY' or
        not $current_season->{meets}->@*
    ) {
        $self->flash( memo => {
            class   => 'error',
            message => 'There is an error in the settings for the region. Please notify the administration.',
        } );
        $self->redirect_to('/');
    }
    else {
        $self->stash( current_season => $current_season );
    }
}

{
    my $reg_conf = conf->get('registration');
    sub register ($self) {
        my ( $method, $format ) = ( $self->req->method, $self->stash('format') );
        my $current_next_meet = $self->_current_next_meet;

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

                admin_edit_override => ( $self->session->{was_user_id} ) ? 1 : 0,
            } );
        }
        elsif ( $method eq 'POST' and my $reg = $self->req->json ) {
            if (
                not $self->session->{was_user_id} and (
                    not $current_next_meet or
                    $current_next_meet->{registration_closed}
                )
            ) {
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
        meet     => $self->_current_next_meet( $self->param('time') ),
        reg_data => CBQ::Model::Registration->new->get_data(
            $self->param('time'),
            $self->stash('req_info')->{region}{key},
            CBQ::Model::Region->new->other_regions(
                $self->stash->{req_info}{region},
                $self->stash->{req_info}{regions},
                $self->param('time'),
            )->@*,
        ),
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
                qw( Organization Acronym Team Nickname Name Bible M/F Rookie ),
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
                        my $team     = $acronym . ' ' . ++$team_count;
                        my $nickname = ( ref $_ eq 'HASH' and $_->{nickname} ) ? $_->{nickname} : '';

                        map {
                            [ grep { defined }
                                $org_name,
                                $acronym,
                                $team,
                                $nickname,
                                $_->{name},
                                $_->{bible},
                                $_->{m_f},
                                $_->{rookie},
                                ( $data->{meet}{host}{housing} ? $_->{housing} : undef ),
                                ( $data->{meet}{host}{lunch} ? $_->{lunch} : undef ),
                                '',
                            ];
                        }
                        ( ref $_ eq 'HASH' ) ? $_->{quizzers}->@* : @$_;
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

sub verses ($self) {
    my $reg            = CBQ::Model::Registration->new;
    my $time           = time;
    my $current_season = $self->_current_season;
    my $regions        = [
        $self->stash('req_info')->{region}{key},
        CBQ::Model::Region->new->other_regions(
            $self->stash->{req_info}{region},
            $self->stash->{req_info}{regions},
            $time,
        )->@*,
    ];
    my $reg_data = $reg->get_data( $time, @$regions );

    my @meets;
    while ( my $meet = shift $current_season->{meets}->@* ) {
        next unless ( $meet->{deadline} );
        chomp( $meet->{name} );
        $meet->{name} =~ s/<[^>]+>//g;
        push( @meets, $meet );
        last unless ( $meet->{stop_time} <= $time );
    }

    my $verses_data;
    for my $org_acronym ( map { $_->{acronym} } $reg_data->{orgs}->@* ) {
        for my $meet (@meets) {
            my $info = $reg->last_info(
                $org_acronym,
                $current_season->{start_time},
                $meet->{start_time},
                $regions,
            );
            next unless ($info);

            my $quizzer_verses = {
                map { $_->{name}  => $_->{verses} }
                grep { $_->{name} }
                map { ( ref $_ eq 'HASH' ) ? $_->{quizzers}->@* : @$_ }
                map { $_->{teams}->@* }
                $info->{orgs}->@*
            };

            $verses_data->{ $_->{team}{acronym} }{ $_->{name} }{ $meet->{name} } =
                0 + $quizzer_verses->{ $_->{name} }
                for ( grep { exists $quizzer_verses->{ $_->{name} } } $reg_data->{quizzers_by_verses}->@* );
        }
    }

    my @meet_names = map { $_->{name} } @meets;
    my @rows;
    for my $org_acronym ( keys %$verses_data ) {
        for my $quizzer_name ( keys $verses_data->{$org_acronym}->%* ) {
            push( @rows, [
                $quizzer_name,
                $org_acronym,
                map { $verses_data->{$org_acronym}{$quizzer_name}{$_} // '' } @meet_names,
            ] );
        }
    }

    @rows = sort {
        my $s = 0;
        for ( reverse 2 .. @$a - 1 ) {
            my $ts = ( $b->[$_] || 0 ) <=> ( $a->[$_] || 0 );
            if ( $ts != 0 ) {
                $s = $ts;
                last;
            }
        }
        $s or $a->[0] cmp $b->[0];
    }
    @rows;

    unshift( @rows, [
        'Quizzer',
        'Org.',
        @meet_names,
    ] );

    csv( out => \my $csv, in => \@rows );
    my $filename = 'ytd_verses.csv';

    $self->res->headers->content_type('text/csv; charset=utf-8');
    $self->res->headers->content_disposition(qq{attachment; filename="$filename"});

    $self->render( data => $csv );
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

=head2 verses

Handler for downloading season verse counts as CSV.

=head1 INHERITANCE

L<Mojolicious::Controller>.
