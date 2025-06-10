package CBQ::Control::Org;

use exact -conf, 'Mojolicious::Controller';
use CBQ::Model::Org;
use CBQ::Model::Region;

sub list ($self) {
    my ( $regions_orgs, $last_seen_region ) = ( [], '' );
    for my $org (
        CBQ::Model::Org->orgs(
            ( $self->stash->{req_info}{region} ) ? $self->stash->{req_info}{region}{key}: undef
        )->@*
    ) {
        if ( $last_seen_region ne $org->{region_acronym} ) {
            $last_seen_region = $org->{region_acronym};
            push( @$regions_orgs, [] );
        }
        push( @{ $regions_orgs->[-1] }, $org );
    }

    $self->stash(
        regions_orgs       => $regions_orgs,
        org_and_region_ids => $self->stash('user')->org_and_region_ids,
    );
}

sub view ($self) {
    my $org = CBQ::Model::Org->new->load( $self->param('org_id') );
    $self->stash(
        org     => $org,
        regions => $org->regions,
        users   => $org->users,
    );
}

sub crud ($self) {
    my $regions = CBQ::Model::Region->new->every_data;
    my $org     = ( $self->param('org_id') )
        ? CBQ::Model::Org->new->load( $self->param('org_id') )
        : undef;

    if ( my $usage = $self->param('usage') ) {
        my %params = $self->req->params->to_hash->%*;
        try {
            unless ( $params{name} and $params{acronym} and $params{address} and $params{regions} ) {
                die 'Incomplete organization information';
            }
            else {
                if ( $usage =~ /create/i ) {
                    $org = CBQ::Model::Org->new->create( {
                        map { $_ => $params{$_} } qw( name acronym address )
                    } );
                    $self->stash('user')->add_org( $params{org_id} );
                }
                elsif ( $usage =~ /edit/i ) {
                    die 'Current user is not authorized to edit the organization' unless (
                        grep { $_ == $params{org_id} } $self->stash('user')->org_and_region_ids->{orgs}->@*
                    );
                    $org->save( { map { $_ => $params{$_} } qw( name acronym address ) } );
                }
                $org->regions( $params{regions} );
            }

            $self->redirect_to( '../' . $self->stash('path_part_prefix') . '/user/tools' );
        }
        catch ($e) {
            $self->notice($e);
            $self->stash( memo => { class => 'error', message => deat($e) }, %params );
        }
    }

    if ( my $regions_org_is_in = ($org) ? $org->regions : undef ) {
        $regions = [ grep {
            my $region = $_;

            $region->{org_is_in} = (
                grep { $_->{region_id} == $region->{region_id} } $regions_org_is_in->@*
            ) ? 1 : 0;

            $region;
        } @$regions ];
    }
    elsif ( my $region_req_info = $self->stash->{req_info}{region} ) {
        my ($this_region) = grep { lc $_->{acronym} eq $region_req_info->{key} } @$regions;
        $this_region->{org_is_in} = 1 if ($this_region);
    }

    $self->stash(
        regions => $regions,
        ($org) ? ( org => $org, $org->data->%* ) : (),
    );
}

1;

=head1 NAME

CBQ::Control::Org

=head1 DESCRIPTION

This class is a subclass of L<Mojolicious::Controller> and provides handlers
for "org" (team organization) actions.

=head1 METHODS

=head2 list

Handler for org list (or index page).

=head2 view

Handler for org view page.

=head2 crud

Handler for create and edit team organization pages.

=head1 INHERITANCE

L<Mojolicious::Controller>.
