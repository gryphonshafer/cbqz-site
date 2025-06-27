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

=head1 WITH ROLE

L<Omniframe::Role::Model>.
