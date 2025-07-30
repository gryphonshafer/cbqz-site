package CBQ::Model::Registration;

use exact -class, -conf;
use Mojo::JSON qw( to_json from_json );

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
                    r.created,
                    ro.org_id
                FROM registration AS r
                LEFT JOIN registration_org AS ro USING (registration_id)
                WHERE
                    r.region_id = ? AND (
                        ro.org_id IN ( } . join( ',',
                            map { $self->dq->quote($_) } $user->org_and_region_ids->{orgs}->@*
                        ) . q{ ) OR
                        ( ro.registration_id IS NULL AND user_id = ? )
                    )
                ORDER BY created DESC
            )
            SELECT *
            FROM reg_rows
            GROUP BY org_id
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

    $reg->{orgs} //= [
        map { +{
            org_id      => $_->{org_id},
            name        => $_->{name},
            acronym     => $_->{acronym},
            teams       => [],
            nonquizzers => [],
        } }
        CBQ::Model::Org->new->every_data({
            org_id => $user->org_and_region_ids->{orgs},
        })->@*
    ];

    for my $reg_row ( grep { defined $_->{org_id} } @$grouped_reg_rows ) {
        my ($org_block) = grep { $reg_row->{org_id} == $_->{org_id} } $reg_row->{info}{orgs}->@*;
        if ($org_block) {
            $reg->{orgs} = [ grep { $reg_row->{org_id} != $_->{org_id} } $reg->{orgs}->@* ];
            push( @{ $reg->{orgs} }, $org_block );
        }
    }

    return $reg;
}

sub get_data ( $self, $region_id ) {
    my $reg_data = [
        map {
            $_->{info} = $self->thaw($_)->{info};
            $_;
        }
        $self->dq->sql(q{
            WITH reg_rows AS (
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
                WHERE r.region_id = ? AND u.active
                ORDER BY r.created DESC
            )
            SELECT *
            FROM reg_rows
            GROUP BY org_id
        })->run($region_id)->all({})->@*
    ];

    my $registrants = { map { $_->{user_id} => $_ } grep { $_->{info}{user}{attend} } @$reg_data };
    my $orgs        = [
        sort { $a->{acronym} cmp $b->{acronym} }
        map {
            my $org_id = $_->{org_id};
            my ($org) = grep { $org_id == $_->{org_id} } $_->{info}{orgs}->@*;
            $org->{created} = $_->{created};

            $org->{teams} = [
                grep { @$_ }
                map { [ grep { $_->{attend} } @$_ ] }
                $org->{teams}->@*
            ];

            $org->{nonquizzers} = [
                grep { $_->{attend} }
                $org->{nonquizzers}->@*
            ];

            $org;
        }
        grep { $_->{org_id} }
        @$reg_data
    ];

    my $quizzers_by_verses = [];
    for my $org (@$orgs) {
        my $number = 0;
        for my $team ( $org->{teams}->@* ) {
            $number++;
            for my $quizzer (@$team) {
                push( @$quizzers_by_verses, {
                    %$quizzer,
                    team => {
                        name    => $org->{name},
                        acronym => $org->{acronym},
                        number  => $number,
                    },
                } );
            }
        }
    }

    return {
        registrants        => [ sort { $a->{name} cmp $b->{name} } values %$registrants ],
        orgs               => $orgs,
        quizzers_by_verses => [
            sort {
                $b->{verses} cmp $a->{verses} or
                $b->{name} cmp $a->{name}
            }
            @$quizzers_by_verses
        ],
        orgs_by_reg_date => [ sort { $b->{created} cmp $a->{created} } @$orgs ],
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
                ORDER BY r.created DESC
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
    })->run($region_id)->column;
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

=head1 WITH ROLE

L<Omniframe::Role::Model>.
