package CBQ::Model::Org;

use exact -class, -conf;

with 'Omniframe::Role::Model';

sub orgs ( $self, $region = undef ) {
    return $self->dq->get(
        [
            'org',
            [ 'org_region', 'org_id' ],
            [ 'region', 'region_id' ],
        ],
        [
            { 'org.org_id'     => 'org_id'         },
            { 'org.name'       => 'org_name'       },
            { 'org.acronym'    => 'org_acronym'    },
            { 'org.address'    => 'org_address'    },
            { 'region.name'    => 'region_name'    },
            { 'region.acronym' => 'region_acronym' },
        ],
        {
            'org.active'    => 1,
            'region.active' => 1,
            ( ($region) ? ( 'region.acronym' => { '-like' => $region } ) : () ),
        },
        { order_by => [ 'region.name', 'org.name' ] },
    )->run->all({});
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

=head1 WITH ROLE

L<Omniframe::Role::Model>.
