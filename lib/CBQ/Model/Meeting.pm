package CBQ::Model::Meeting;

use exact -class;
use Mojo::JSON qw( encode_json decode_json );
use Text::MultiMarkdown 'markdown';

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

sub _markdownificate ($text) {
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    return markdown $text;
}

sub thaw ( $self, $data ) {
    $data->{info} = ( defined $data->{info} ) ? decode_json( $data->{info} ) : {};

    $_ = _markdownificate($_) for (
        $data->{location},
        $data->{info}{agenda},
        $data->{info}{motions}->@*,
    );

    return $data;
}

sub is_active ($self) {
    return (
        not $self->data->{info}{closed} and
        $self->time->parse( $self->data->{start} )->datetime->epoch <= time
    ) ? 1 : 0;
}

sub open_meetings ($self) {
    return [
        sort {
            $a->data->{start} cmp $b->data->{start}
        }
        $self->every({
            -or => [
                \q{ JSON_EXTRACT( info, '$.closed' ) IS NULL },
                \q{ JSON_EXTRACT( info, '$.closed' ) = 0 },
            ],
        })->@*
    ];
}

sub attended_meetings ( $self, $user ) {
    return $self->dq->sql( q{
        SELECT m.start
        FROM meeting AS M
        JOIN user_meeting AS um USING (meeting_id)
        WHERE um.user_id = ?
    } )->run( $user->id )->all({});
}

sub viewed ( $self, $user ) {
    $self->dq->sql( q{
        INSERT OR IGNORE INTO user_meeting ( user_id, meeting_id ) VALUES ( ?, ? )
    } )->run( $user->id, $self->id ) if ( $self->is_active );
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
    my $info = decode_json( $self->dq->sql( q{
        SELECT info FROM user_meeting WHERE user_id = ? AND meeting_id = ?
    } )->run( $user->id, $self->id )->value // '{}' );

    $info->{votes}{ $params->{motion} } = $params->{ballot};

    $self->dq->sql( q{
        UPDATE user_meeting SET info = ? WHERE user_id = ? AND meeting_id = ?
    } )->run( encode_json($info), $user->id, $self->id );
}

sub votes ( $self, $user ) {
    return decode_json( $self->dq->sql( q{
        SELECT info FROM user_meeting WHERE user_id = ? AND meeting_id = ?
    } )->run( $user->id, $self->id )->value // '{}' )->{votes};
}

sub all_votes ($self) {
    my $all_votes;

    for my $votes (
        grep { $_ }
        map { decode_json( $_ // {} )->{votes} }
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

=head2 open_meetings

Sorted list of meeting objects where the meeting isn't closed.

=head2 attended_meetings

Data list of meetings that the user has attended.

=head2 viewed

Mark the current meeting as viewed (i.e. attended) by the user.

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

=head1 WITH ROLES

L<Omniframe::Role::Model>, L<Omniframe::Role::Time>.
