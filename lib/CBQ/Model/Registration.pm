package CBQ::Model::Registration;

use exact -class;
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

sub get_reg ( $self, $user ) {
    my $grouped_reg_rows = $self->dq->sql(q{
        WITH reg_rows AS (
            SELECT
                r.user_id,
                r.info,
                r.created,
                ro.org_id
            FROM registration AS r
            LEFT JOIN registration_org AS ro USING (registration_id)
            WHERE
                ro.org_id IN ( } . join( ',',
                    map { $self->dq->quote($_) } $user->org_and_region_ids->{orgs}->@*
                ) . q{ ) OR
                ( ro.registration_id IS NULL AND user_id = ? )
            ORDER BY created DESC
        )
        SELECT *
        FROM reg_rows
        GROUP BY org_id
    })->run( $user->id )->all({});

    my ($reg) = map { $self->thaw($_)->{info} } grep { not defined $_->{org_id} } @$grouped_reg_rows;

    $reg //= {
        user => {
            roles => $user->data->{info}{roles} // [],
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

    for my $reg_row (
        map { +{
            org_id => $_->{org_id},
            info   => $self->thaw($_)->{info},
        } }
        grep { defined $_->{org_id} } @$grouped_reg_rows
    ) {
        my ($org_block) = grep { $reg_row->{org_id} == $_->{org_id} } $reg_row->{info}{orgs}->@*;
        if ($org_block) {
            $reg->{orgs} = [ grep { $reg_row->{org_id} != $_->{org_id} } $reg->{orgs}->@* ];
            push( @{ $reg->{orgs} }, $org_block );
        }
    }

    return $reg;
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

=head1 WITH ROLE

L<Omniframe::Role::Model>.
