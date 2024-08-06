package CBQ::Control::User;

use exact -conf, 'Mojolicious::Controller';
use CBQ::Model::User;

sub sign_up_or_login ($self) {
    my %params = $self->req->params->to_hash->%*;

    if ( $params{type} eq 'signup' ) {
        my @fields = qw( email passwd first_name last_name phone );

        try {
            die 'Email, password, first and last name, and phone fields must be filled in'
                if ( grep { length $params{$_} == 0 } @fields );

            $self->_captcha;

            unless ( $self->stash('user') ) {
                my $user = CBQ::Model::User->new->create({ map { $_ => $params{$_} } @fields });

                if ( $user and $user->data ) {
                    $user->send_email( 'verify_email', $self->url_for('/user/verify') );

                    my $email = {
                        to   => $user->data->{email},
                        from => $user->conf->get( qw( email from ) ),
                    };
                    $email->{$_} =~ s/(<|>)/ ( $1 eq '<' ) ? '&lt;' : '&gt;' /eg for ( qw( to from ) );

                    $self->info( 'User create success: ' . $user->id );
                    $self->flash(
                        message => {
                            type => 'success',
                            text => join( ' ',
                                'Successfully created user with email address: ' .
                                    '<b>' . $email->{to} . '</b>.',
                                'Check your email for reception of the verification email.',
                                'If you don\'t see the verification email in a couple minutes, ' .
                                    'check your spam folder.',
                                'Contact <b>' . $email->{from} . '</b> if you need help.',
                            ),
                        }
                    );
                    $self->redirect_to('/');
                }
            }
        }
        catch ($e) {
            if ( $e =~ /\bcaptcha\b/i ) {
                $e =~ s/\s+at\s+(?:(?!\s+at\s+).)*[\r\n]*$//;
                $self->stash( message => $e );
            }
            else {
                $e =~ s/\s+at\s+(?:(?!\s+at\s+).)*[\r\n]*$//;
                $e =~ s/^"([^""]+)"/ '"' . join( ' ', map { ucfirst($_) } split( '_', $1 ) ) . '"' /e;
                $e =~ s/DBD::\w+::st execute failed:\s*//;
                $e .= '. Please try again.';

                $e = "Value in $1 field is already registered under an existing user account."
                    if ( $e =~ /UNIQUE constraint failed/ );

                $self->info("User create failure: $e");
                $self->stash( message => $e, %params );
            }
        }
    }
    elsif ( $params{type} eq 'login' ) {

    }
}

1;

=head1 NAME

CBQ::Control::User

=head1 DESCRIPTION

This class is a subclass of L<Mojolicious::Controller> and provides handlers
for "user" actions.

=head1 METHODS

=head2 ???

Handler for...

=head1 INHERITANCE

L<Mojolicious::Controller>.
