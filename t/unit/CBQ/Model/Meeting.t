use Test2::V0;
use exact -conf;
use CBQ::Model::Meeting;

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

done_testing;
