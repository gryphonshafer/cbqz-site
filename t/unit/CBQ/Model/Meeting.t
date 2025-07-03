use Test2::V0;
use exact -conf;
use CBQ::Model::Meeting;
use CBQ::Model::User;

my $obj;
ok( lives { $obj = CBQ::Model::Meeting->new }, 'new' ) or note $@;
DOES_ok( $obj, 'Omniframe::Role::Model' );
can_ok( $obj, qw(
    freeze thaw
    is_active open_meetings past_meetings
    viewed
    vote_create vote
    votes all_votes
    close
) );

$obj->dq->begin_work;

$obj->create({
    start    => '2024-10-25 12:34:56',
    location => 'Test Suite',
    info     => {
        agenda  => "1. Chancellor's Report\n2. Semiannual Confidence Vote *(as per bylaws section 2.1)*",
        motions => [ 'Semiannual Confidence Vote' ],
    },
});

is( $obj->is_active, T(), 'is_active' );
is( $obj->is_closed, F(), 'is_closed' );

my $open_meetings = $obj->open_meetings;
isa_ok( $open_meetings->[0], 'CBQ::Model::Meeting' );
my ($obj2) = grep { $_->data->{start} eq '2024-10-25 12:34:56' } @$open_meetings;
is( $obj2->id, $obj->id, 'open meeting' );

my $user = CBQ::Model::User->new->create({
    email      => 'example@example.com',
    passwd     => 'terrible_but_long_password',
    first_name => 'first_name',
    last_name  => 'last_name',
    phone      => '1234567890',
    active     => 1,
});

ok( lives { $obj->viewed($user) }, 'viewed' ) or note $@;
is( scalar( grep { $_->{email} eq 'example@example.com' } $obj->attendees->@* ), 1, 'attendees' );
ok( lives { $obj->vote_create('New motion') }, 'vote_create' ) or note $@;

ok( lives { $obj->vote( $user, {
    motion => 'New motion',
    ballot => 'Yea',
} ) }, 'vote' ) or note $@;

is( $obj->votes($user), { 'New motion' => 'Yea' }, 'votes' );
is( $obj->all_votes, { 'New motion' => { 'Yea' => 1 } }, 'all_votes' );

$obj->close;
is(
    scalar( grep { $_->{attended} and $_->{meeting_id} == $obj->id } $obj->past_meetings($user)->@* ),
    1,
    'past_meetings',
);

$obj->dq->rollback;

done_testing;
