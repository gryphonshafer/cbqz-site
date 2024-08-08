package CBQ::Model::Meeting;

use exact -class;
use Mojo::JSON qw( encode_json decode_json );

with qw( Omniframe::Role::Model Omniframe::Role::Time );

around 'create' => sub ( $orig, $self, $params ) {
    try {
        $params->{start} = $self->time->parse( $params->{start} )->format('ansi');
    }
    catch ($e) {
        die 'Unable to parse start date/time';
    }
    $params->{info} = { agenda => delete $params->{agenda} };
    return $orig->( $self, $params );
};

sub freeze ( $self, $data ) {
    $data->{info} = encode_json( $data->{info} );
    undef $data->{info} if ( $data->{info} eq '{}' or $data->{info} eq 'null' );

    return $data;
}

sub thaw ( $self, $data ) {
    $data->{info} = ( defined $data->{info} ) ? decode_json( $data->{info} ) : {};
    return $data;
}

sub is_open ($self) {
    return (
        not $self->data->{info}{closed} and
        $self->time->parse( $self->data->{start} )->datetime->epoch <= time
    ) ? 1 : 0;
}

sub viewed ( $self, $user ) {
    if ( $self->is_open ) {
        $self->dq->sql( q{
            INSERT OR IGNORE INTO user_meeting ( user_id, meeting_id ) VALUES ( ?, ? )
        } )->run( $user->id, $self->id )
    }
}

1;

=head1 NAME

CBQ::Model::Meeting

=head1 SYNOPSIS

    use CBQ::Model::Meeting;

=head1 DESCRIPTION

This class is the model for meeting objects.

=head1 EXTENDED METHOD

=head1 OBJECT METHODS

=head2 freeze

Likely not used directly, this method is provided to JSON-encode the C<info>
hashref.

=head2 thaw

Likely not used directly, C<thaw> will JSON-decode the C<info> hashref.

=head2 is_open

Returns true if the meeting is open, defined as start time is now or in the past
and the meeting isn't closed.

=head2 viewed

Inserts a "user viewed the meeting page" record if one doesn't already exist.

=head1 WITH ROLES

L<Omniframe::Role::Model>, L<Omniframe::Role::Time>.
