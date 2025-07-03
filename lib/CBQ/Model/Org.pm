package CBQ::Model::Org;

use exact -class;
use CBQ::Model::Region;
use CBQ::Model::User;

with 'Omniframe::Role::Model';

class_has active => 1;

sub orgs ( $self, $region = undef ) {
    return $self->dq->get(
        [
            'org',
            [ 'org_region', 'org_id' ],
            [ 'region', 'region_id' ],
        ],
        [
            { 'org.org_id'       => 'org_id'         },
            { 'org.name'         => 'org_name'       },
            { 'org.acronym'      => 'org_acronym'    },
            { 'org.address'      => 'org_address'    },
            { 'region.region_id' => 'region_id'      },
            { 'region.name'      => 'region_name'    },
            { 'region.acronym'   => 'region_acronym' },
        ],
        {
            'org.active'    => 1,
            'region.active' => 1,
            ( ($region) ? ( 'region.acronym' => { '-like' => $region } ) : () ),
        },
        { order_by => [ 'region.name', 'org.name' ] },
    )->run->all({});
}

sub regions ( $self, $regions = undef ) {
    return unless ( $self->id );
    unless ($regions) {
        return [ CBQ::Model::Region->new->every_data({
            region_id => [
                $self->dq->sql( q{
                    SELECT or.region_id
                    FROM org_region AS or
                    JOIN region AS r USING (region_id)
                    WHERE or.org_id = ? AND r.active
                } )->run( $self->id )->column
            ],
        }) ];
    }
    else {
        $regions = [$regions] unless ( ref $regions eq 'ARRAY' );

        my $ids = $self->dq
            ->get( 'org_region', ['region_id'], { org_id => $self->id } )
            ->run->column;

        $self->dq->add( 'org_region', { org_id => $self->id, region_id => $_ } ) for (
            grep {
                my $id = $_;
                not grep { $id == $_ } $ids->@*;
            } @$regions
        );

        $self->dq->rm( 'org_region', { org_id => $self->id, region_id => $_ } ) for (
            grep {
                my $id = $_;
                not grep { $id == $_ } @$regions;
            } $ids->@*
        );

        return;
    }
}

sub users ($self) {
    return unless ( $self->id );
    return [ CBQ::Model::User->new->every_data({
        user_id => [
            $self->dq->sql( q{
                SELECT uo.user_id
                FROM user_org AS uo
                JOIN user AS u USING (user_id)
                WHERE uo.org_id = ? AND u.active
            } )->run( $self->id )->column
        ],
    }) ];
}

1;

=head1 NAME

CBQ::Model::Org

=head1 SYNOPSIS

    use CBQ::Model::Org;

=head1 DESCRIPTION

This class is the model for quiz team organization objects and associated scalar
and list methods.

=head1 METHODS

=head2 orgs

Returns an arrayref of hashrefs of active organizations. If an optional region
acronym is provided, it'll return only those active organizations from the
region (and only if that region is also active).

=head2 regions

Returns all the regions of which the org is a part.

=head2 users

Returns all the users of which the org is a part.

=head1 WITH ROLE

L<Omniframe::Role::Model>.
