package CBQ::Model::Meeting;

use exact -class;
use Mojo::JSON qw( to_json from_json );
use Omniframe::Class::Time;

with 'Omniframe::Role::Model';

my $time = Omniframe::Class::Time->new;

around 'create' => sub ( $orig, $self, $params ) {
    try {
        $params->{start} = $time->parse( $params->{start} )->format('ansi');
    }
    catch ($e) {
        die 'Unable to parse start date/time';
    }
    $params->{info} = { agenda => delete $params->{agenda} };
    return $orig->( $self, $params );
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

sub is_active ($self) {
    return (
        not $self->data->{info}{closed} and
        $time->parse( $self->data->{start} )->datetime->epoch <= time
    ) ? 1 : 0;
}

sub is_closed ($self) {
    return $self->data->{info}{closed};
}

sub open_meetings ($self) {
    return [
        sort { $a->data->{start} cmp $b->data->{start} }
        $self->every({
            -or => [
                \q{ JSON_EXTRACT( info, '$.closed' ) IS NULL },
                \q{ JSON_EXTRACT( info, '$.closed' ) = 0 },
            ],
        })->@*
    ];
}

sub past_meetings ( $self, $user ) {
    return $self->dq->sql( q{
        SELECT
            m.meeting_id,
            m.start,
            SUM( CASE WHEN um.user_id = ? THEN 1 ELSE 0 END ) AS attended
        FROM meeting AS m
        JOIN user_meeting AS um USING (meeting_id)
        WHERE JSON_EXTRACT( m.info, '$.closed' ) = 1
        GROUP BY 1
    } )->run( $user->id )->all({});
}

sub viewed ( $self, $user ) {
    $self->dq->sql( q{
        INSERT OR IGNORE INTO user_meeting ( user_id, meeting_id ) VALUES ( ?, ? )
    } )->run( $user->id, $self->id ) if ( $self->is_active );
}

sub attendees ($self) {
    return $self->dq->sql( q{
        SELECT
            u.first_name,
            u.last_name,
            u.email,
            u.phone
        FROM user AS u
        JOIN user_meeting AS um USING (user_id)
        WHERE um.meeting_id = ?
    } )->run( $self->id )->all({});
}

sub vote_create ( $self, $motion ) {
    unless ( $self->data->{info}{closed} ) {
        my %motions = map { $_ => 1 } @{ $self->data->{info}{motions} };
        push( @{ $self->data->{info}{motions} }, $motion ) unless ( $motions{$motion} );
        $self->save;
    }
    return $self;
}

sub vote ( $self, $user, $params ) {
    return unless ( $self->is_active );

    my $info = from_json( $self->dq->sql( q{
        SELECT info FROM user_meeting WHERE user_id = ? AND meeting_id = ?
    } )->run( $user->id, $self->id )->value // '{}' );

    $info->{votes}{ $params->{motion} } = $params->{ballot};

    $self->dq->sql( q{
        UPDATE user_meeting SET info = ? WHERE user_id = ? AND meeting_id = ?
    } )->run( to_json($info), $user->id, $self->id );
}

sub votes ( $self, $user ) {
    return from_json( $self->dq->sql( q{
        SELECT info FROM user_meeting WHERE user_id = ? AND meeting_id = ?
    } )->run( $user->id, $self->id )->value // '{}' )->{votes};
}

sub all_votes ($self) {
    my $all_votes;

    for my $votes (
        grep { $_ }
        map { from_json( $_ // '{}' )->{votes} }
        $self->dq->sql( q{
            SELECT info FROM user_meeting WHERE meeting_id = ?
        } )->run( $self->id )->column->@*
    ) {
        $all_votes->{$_}{ $votes->{$_} }++ for ( keys %$votes );
    }

    return $all_votes;
}

sub close ($self) {
    $self->data->{info}{closed} = 1;
    $self->save;
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

=head2 is_active

Returns boolean for if the loaded meeting is "active" (meaning the meeting isn't
closed and the start was now or in the past).

=head2 is_closed

Returns boolean for if the loaded meeting is closed.

=head2 open_meetings

Sorted list of meeting objects where the meeting isn't closed.

=head2 past_meetings

Data list of past meetings.

=head2 viewed

Mark the current meeting as viewed (i.e. attended) by the user.

=head2 attendees

List of users who attended the meeting.

=head2 vote_create

Create a motion for the meeting.

=head2 vote

Vote on a motion of the meeting.

=head2 votes

Return data of the votes the user made at the meeting.

=head2 all_votes

Return summary data of all votes made by all users at the meeting.

=head2 close

Close the meeting.

=head1 WITH ROLE

L<Omniframe::Role::Model>.
