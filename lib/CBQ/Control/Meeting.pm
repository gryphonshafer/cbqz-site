package CBQ::Control::Meeting;

use exact -conf, 'Mojolicious::Controller';
use CBQ::Model::Meeting;
use Omniframe::Util::Text 'deat';

sub create ($self) {
    my $params = $self->req->params->to_hash;
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
                    message => deat($e) . '.',
                );
            }
        }
    }
}

sub view ($self) {
    my $meeting = CBQ::Model::Meeting->new->load( $self->param('meeting_id') );
    $meeting->viewed( $self->stash('user') );
    $self->stash( meeting => $meeting );
}

sub vote_create ($self) {
    my $meeting = CBQ::Model::Meeting->new->load( $self->param('meeting_id') );
    unless ( $meeting->data->{info}{closed} ) {
        push( @{ $meeting->data->{info}{votes} }, { motion => $self->param('motion') } );
        $meeting->save;
    }
    $self->redirect_to( '/meeting/' . $self->param('meeting_id') );
}

sub vote ($self) {
    push( @{ $self->stash('user')->data->{info}{votes} }, $self->req->params->to_hash );
    $self->redirect_to( '/meeting/' . $self->param('meeting_id') );
}

sub close ($self) {
    my $meeting = CBQ::Model::Meeting->new->load( $self->param('meeting_id') );
    $meeting->data->{info}{closed} = 1;
    $meeting->save;
    $self->redirect_to('/user/tools');
}

1;

=head1 NAME

CBQ::Control::Meeting

=head1 DESCRIPTION

This class is a subclass of L<Mojolicious::Controller> and provides handlers
for "user" actions.

=head1 METHODS

=head2 create

Handler for meeting creation.

=head2 view

Handler for viewing a meeting.

=head2 vote_create

Handler for creating a vote item (something to be voted on) in a meeting.

=head2 vote

Handler for viewing and casting a vote.

=head2 close

Handler for closing a meeting.

=head1 INHERITANCE

L<Mojolicious::Controller>.
