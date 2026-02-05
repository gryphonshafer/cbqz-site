package CBQ::Model::Registration;

use exact -class, -conf;
use Mojo::JSON qw( to_json from_json );
use CBQ::Model::Org;

with 'Omniframe::Role::Model';

after 'create' => sub ( $self, $params ) {
    $self->dq->add( 'registration_org', {
        registration_id => $self->id,
        org_id          => $_->{org_id},
    } ) for ( $params->{info}{orgs}->@* );
};

sub freeze ( $self, $data ) {
    $data->{info} = to_json( $data->{info} );
    undef $data->{info} if ( $data->{info} eq '{}' or $data->{info} eq 'null' );
    return $data;
}

sub thaw ( $self, $data ) {
    $data->{info} = ( defined $data->{info} ) ? from_json( $data->{info} ) : {};
    return $data;
}

sub get_reg ( $self, $region_id, $user ) {
    my $grouped_reg_rows = [
        map { $self->thaw($_) }
        $self->dq->sql(q{
            WITH reg_rows AS (
                SELECT
                    r.user_id,
                    r.info,
                    ro.org_id,
                    r.created
                FROM registration AS r
                LEFT JOIN registration_org AS ro USING (registration_id)
                WHERE
                    r.region_id = ? AND (
                        ro.org_id IN ( } . join( ',',
                            map { $self->dq->quote($_) } $user->org_and_region_ids->{orgs}->@*
                        ) . q{ ) OR
                        ( ro.registration_id IS NULL AND user_id = ? )
                    )
            )
            SELECT
                user_id,
                info,
                org_id,
                MAX(created) AS created
            FROM reg_rows
            GROUP BY org_id, user_id
            ORDER BY created DESC
        })->run(
            $region_id,
            $user->id,
        )->all({})->@*
    ];

    my ($reg) = grep { $_->{user_id} == $user->id } @$grouped_reg_rows;
    $reg = $reg->{info} if ($reg);

    $reg //= {
        user => {
            roles => [
                grep {
                    my $this_role = $_;
                    grep { $this_role eq $_ } $user->data->{info}{roles}->@*;
                }
                conf->get( qw{ registration roles } )->@*
            ],
        },
    };

    $reg->{orgs} = [
        grep { defined }
        map {
            my $org_id = $_;
            my $reg;

            my ($row) = grep { $_->{org_id} and $_->{org_id} == $org_id } @$grouped_reg_rows;
            ($reg)    = grep { $_->{org_id} and $_->{org_id} == $org_id } $row->{info}{orgs}->@* if ($row);

            unless ($reg) {
                try {
                    my $org_data = CBQ::Model::Org->new->load($org_id)->data;
                    $reg = {
                        org_id      => $org_data->{org_id},
                        name        => $org_data->{name},
                        acronym     => $org_data->{acronym},
                        teams       => [],
                        nonquizzers => [],
                    };
                }
                catch ($e) {}
            }
            # migrate any v1 reg data instance to v2 structure
            elsif (
                ref $reg->{teams} eq 'ARRAY' and
                @{ $reg->{teams} } and
                ref $reg->{teams}[0] eq 'ARRAY'
            ) {
                $_ = { quizzers => $_ } for ( @{ $reg->{teams} } );
            }

            $reg;
        }
        $user->org_and_region_ids->{orgs}->@*
    ];

    return $reg;
}

sub get_data ( $self, $time = undef, @region_keys ) {
    my $reg_data = [
        map {
            $_->{info} = $self->thaw($_)->{info};
            $_;
        }
        $self->dq->sql(q{
            SELECT
                u.user_id,
                u.email,
                u.first_name || ' ' || u.last_name AS name,
                u.phone,
                r.info,
                r.created,
                ro.org_id
            FROM registration AS r
            JOIN user AS u USING (user_id)
            LEFT JOIN registration_org AS ro USING (registration_id)
            WHERE
                r.region_id IN (
                    SELECT region_id FROM region WHERE acronym IN ( } .
                        join( ', ', map { $self->dq->quote( uc $_ ) } @region_keys ) .
                    q{ )
                )
                AND u.active
                } . ( ($time) ? q{ AND STRFTIME( '%s', r.created ) <= } . $self->dq->quote($time) : '' ) . q{
            ORDER BY r.created DESC
        })->run->all({})->@*
    ];

    my $registrants = { map { $_->{user_id} => $_ } reverse @$reg_data };
    my @registrants = values %$registrants;
    $registrants    = [
        sort { $a->{name} cmp $b->{name} }
        grep { $_->{info}{user}{attend} }
        @registrants
    ];
    my $notes_from_not_attending_registrants = [
        grep { not $_->{info}{user}{attend} and $_->{info}{notes} }
        @registrants
    ];

    my $seen;
    $reg_data = [
        grep { defined }
        map { ( $seen->{ $_->{org_id} }++ ) ? undef : $_ }
        grep { $_->{org_id} }
        @$reg_data
    ];

    my $orgs = [
        sort { $a->{acronym} cmp $b->{acronym} }
        map {
            my $org_id = $_->{org_id};
            my ($org) = grep { $org_id == $_->{org_id} } $_->{info}{orgs}->@*;
            $org->{created} = $_->{created};

            # migrate any v1 reg data instance to v2 structure
            if (
                ref $org->{teams} eq 'ARRAY' and
                @{ $org->{teams} } and
                ref $org->{teams}[0] eq 'ARRAY'
            ) {
                $_ = { quizzers => $_ } for ( @{ $org->{teams} } );
            }

            $org->{teams} = [
                grep { @{ $_->{quizzers} } }
                map {
                    $_->{quizzers} = [ grep { $_->{attend} } @{ $_->{quizzers} || [] } ];
                    $_;
                }
                $org->{teams}->@*
            ];

            $org->{nonquizzers} = [
                grep { $_->{attend} }
                $org->{nonquizzers}->@*
            ];

            $org;
        }
        grep { $_->{org_id} and $_->{info}{user}{attend} }
        @$reg_data
    ];

    my $quizzers_by_verses = [];
    for my $org (@$orgs) {
        my $number = 0;
        for my $team ( $org->{teams}->@* ) {
            $number++;
            for my $quizzer ( @{ $team->{quizzers} || [] } ) {
                push( @$quizzers_by_verses, {
                    %$quizzer,
                    team => {
                        name           => $org->{name},
                        acronym        => $org->{acronym},
                        number         => $number,
                        maybe nickname => $team->{nickname},
                    },
                } );
            }
        }
    }

    return {
        registrants        => $registrants,
        orgs               => $orgs,
        quizzers_by_verses => [
            sort {
                $b->{verses} <=> $a->{verses} or
                $a->{team}{acronym} cmp $b->{team}{acronym} or
                $a->{name} cmp $b->{name}
            }
            @$quizzers_by_verses
        ],
        orgs_by_reg_date                     => [ sort { $b->{created} cmp $a->{created} } @$orgs ],
        notes_from_not_attending_registrants => $notes_from_not_attending_registrants,
    };
}

sub coach_user_ids ( $self, $region_id ) {
    return $self->dq->sql(q{
        WITH grouped_user_data AS (
            WITH user_data AS (
                SELECT
                    u.user_id,
                    u.info AS u_info,
                    r.info AS r_info
                FROM user AS u
                JOIN user_region AS ur USING (user_id)
                LEFT JOIN registration AS r USING (user_id)
                WHERE
                    ur.region_id = ? AND
                    u.active
            )
            SELECT
                user_id,
                u_info,
                r_info
            FROM user_data
            GROUP BY user_id
        )
        SELECT user_id
        FROM grouped_user_data
        WHERE
            (
                JSON_EXTRACT( u_info, '$.dormant' ) IS NULL OR
                JSON_EXTRACT( u_info, '$.dormant' ) != 1
            )
            AND (
                EXISTS (
                    SELECT 1
                    FROM JSON_EACH( u_info, '$.roles' )
                    WHERE value = 'Coach'
                ) OR
                EXISTS (
                    SELECT 1
                    FROM JSON_EACH( r_info, '$.user.roles' )
                    WHERE value = 'Coach'
                )
            )
        ORDER BY user_id
    })->run($region_id)->column;
}

sub last_info ( $self, $org_acronym, $season_start, $last_created, $regions ) {
    my $info = $self->dq->sql( q{
        SELECT r.info
        FROM registration AS r
        JOIN user AS u USING (user_id)
        JOIN user_org USING (user_id)
        JOIN org AS o USING (org_id)
        JOIN org_region USING (org_id)
        JOIN region AS g USING (region_id)
        WHERE
            u.active AND
            o.active AND
            o.acronym = ? AND
            UNIXEPOCH( r.created ) BETWEEN ? AND ? AND
            JSON_ARRAY_LENGTH( JSON_EXTRACT( r.info, '$.orgs' ) ) > 0 AND
            g.acronym IN ( } . join( ', ', map { $self->dq->quote( uc $_ ) } @$regions ) . q{ )
        ORDER BY r.created DESC
        LIMIT 1
    } )->run(
        $org_acronym,
        $season_start,
        $last_created,
    )->value;

    return ($info) ? from_json($info) : undef;
}

1;

=head1 NAME

CBQ::Model::Registration

=head1 SYNOPSIS

    use CBQ::Model::Registration;

=head1 DESCRIPTION

This class is the model for quiz meet data.

=head1 AFTER METHOD

=head2 create

After-ed from L<Omniframe::Role::Model>, this method inserts into the
C<registration_org> join table as appropriate.

=head1 OBJECT METHODS

=head2 freeze

Likely not used directly, this method will JSON-encode the C<info> hashref.

=head2 thaw

Likely not used directly, C<thaw> will JSON-decode the C<info> hashref.

=head2 get_reg

Requires a user object. Will return a single unified registration data block
for all the team organizations the user is associated with (and that have
registration data).

=head2 get_data

Returns registration data for a given region.

=head2 coach_user_ids

Given a region ID, this method will return all active users who are coaches, as
defined by either the user selecting "Coach" as a user role or selecting "Coach"
as a meet role in the most recent registration from that user.

=head2 last_info

Requires an org acronym, the season start time, a last created start time limit,
and an arrayref of region acronyms. Will return the last registration C<info>
data structure for the organization that was created after the season start time
and before the last created start time limit.

=head1 WITH ROLE

L<Omniframe::Role::Model>.
