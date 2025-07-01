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
                WHERE r.region_id = ?
                ORDER BY r.created DESC
            )
            SELECT *
            FROM reg_rows
            GROUP BY org_id
        })->run($region_id)->all({})->@*
    ];

    my $registrants = { map { $_->{user_id} => $_ } grep { $_->{info}{user}{attend} } @$reg_data };

    return {
        orgs => [
            sort { $a->{acronym} cmp $b->{acronym} }
            map {
                my $org_id = $_->{org_id};
                my ($org) = grep { $org_id == $_->{org_id} } $_->{info}{orgs}->@*;

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
        ],
        registrants => [ sort { $a->{name} cmp $b->{name} } values %$registrants ],
    };
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

=head1 WITH ROLE

L<Omniframe::Role::Model>.
