package CBQ::Control::Meeting;

use exact 'Mojolicious::Controller';
use CBQ::Model::Meeting;

sub list ($self) {
    my $meeting = CBQ::Model::Meeting->new;

    $self->stash(
        open_meetings => $meeting->open_meetings,
        past_meetings => $meeting->past_meetings( $self->stash('user') ),
    );
}

sub create ($self) {
    return $self->redirect_to('/user/tools') unless ( $self->stash('user')->is_qualified_delegate );

    my $params = $self->req->params->to_hash;
    delete $params->{ $self->csrf->token_name  };

    if (%$params) {
        unless ( $params->{start} and $params->{location} and $params->{agenda} ) {
            $self->stash(%$params);
        }
        else {
            try {
                $self->redirect_to( '/meeting/' . CBQ::Model::Meeting->new->create($params)->id );
            }
            catch ($e) {
                $self->stash(
                    %$params,
                    memo => { class => 'error', message => deat($e) },
                );
            }
        }
    }
}

sub view ($self) {
    my $meeting = CBQ::Model::Meeting->new->load( $self->param('meeting_id') );
    $meeting->viewed( $self->stash('user') );
    $self->stash(
        meeting => $meeting,
        votes   => $meeting->votes( $self->stash('user') ),
    );
}

sub vote_create ($self) {
    return $self->redirect_to('/user/tools') unless ( $self->stash('user')->is_qualified_delegate );

    my $meeting = CBQ::Model::Meeting->new->load( $self->param('meeting_id') );
    $meeting->vote_create( $self->param('motion') );
    $self->redirect_to( '/meeting/' . $self->param('meeting_id') );
}

sub vote_delete ($self) {
    return $self->redirect_to('/user/tools') unless ( $self->stash('user')->is_qualified_delegate );

    my $meeting = CBQ::Model::Meeting->new->load( $self->param('meeting_id') );
    $meeting->vote_delete( $self->param('motion') );
    $self->redirect_to( '/meeting/' . $self->param('meeting_id') );
}

sub vote ($self) {
    return $self->redirect_to('/user/tools') unless ( $self->stash('user')->is_qualified_delegate );

    my $params = $self->req->params->to_hash;
    delete $params->{ $self->csrf->token_name  };

    CBQ::Model::Meeting->new
        ->load( $self->param('meeting_id') )
        ->vote( $self->stash('user'), $params );

    $self->redirect_to( '/meeting/' . $self->param('meeting_id') );
}

sub unvote ($self) {
    return $self->redirect_to('/user/tools') unless ( $self->stash('user')->is_qualified_delegate );

    my $params = $self->req->params->to_hash;
    delete $params->{ $self->csrf->token_name  };

    CBQ::Model::Meeting->new
        ->load( $self->param('meeting_id') )
        ->unvote( $self->stash('user'), $params );

    $self->redirect_to( '/meeting/' . $self->param('meeting_id') );
}

sub close ($self) {
    return $self->redirect_to('/user/tools') unless ( $self->stash('user')->is_qualified_delegate );

    CBQ::Model::Meeting->new->load( $self->param('meeting_id') )->close;
    $self->redirect_to('/user/tools');
}

1;

=head1 NAME

CBQ::Control::Meeting

=head1 DESCRIPTION

This class is a subclass of L<Mojolicious::Controller> and provides handlers
for "user" actions.

=head1 METHODS

=head2 list

Handler for meeting list (or index page).

=head2 create

Handler for meeting creation.

=head2 view

Handler for viewing a meeting.

=head2 vote_create

Handler for creating a vote item (something to be voted on) in a meeting.

=head2 vote_delete

Handler for deleting a vote item (something to be voted on) in a meeting.

=head2 vote

Handler for viewing and casting a vote.

=head2 unvote

Handler for removing a vote.

=head2 close

Handler for closing a meeting.

=head1 INHERITANCE

L<Mojolicious::Controller>.
