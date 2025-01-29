package CBQ::Control::User;

use exact -conf, 'Mojolicious::Controller';
use CBQ::Model::User;
use CBQ::Model::Meeting;

sub sign_up ($self) {
    my %params = $self->req->params->to_hash->%*;

    if ( $params{usage} and $params{usage} eq 'sign_up' ) {
        my @fields = qw( email passwd first_name last_name phone );
        $self->stash( map { $_ => $params{$_} } @fields );

        try {
            die 'Email, password, first and last name, and phone fields must be filled in'
                if ( grep { length $params{$_} == 0 } @fields );

            $self->_captcha;

            my $user = CBQ::Model::User->new->create({ map { $_ => $params{$_} } @fields });

            if ( $user and $user->data ) {
                $user->send_email( 'verify_email', $self->url_for('/user/verify') );

                my $email = {
                    to   => $user->data->{email},
                    from => conf->get( qw( email from ) ),
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

    $self->stash( usage => 'sign_up' );
    $self->render( template => 'user/account' );
}

sub edit ($self) {
    my %params = ( $self->stash('user')->data->%*, $self->req->params->to_hash->%* );
    my @fields = qw( email passwd first_name last_name phone );
    $self->stash( map { $_ => $params{$_} } grep { $_ ne 'passwd' } @fields );

    if ( $params{usage} and $params{usage} eq 'edit' ) {
        try {
            $self->stash('user')->data->{$_} = $params{$_} for ( grep { $params{$_} } @fields );
            $self->stash('user')->save;

            $self->flash(
                message => {
                    type => 'success',
                    text => 'Successfully saved user data.',
                }
            );

            $self->redirect_to('/user/tools');
        }
        catch ($e) {
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

    $self->stash( usage => 'edit' );
    $self->render( template => 'user/account' );
}

sub verify ($self) {
    if ( CBQ::Model::User->new->verify( $self->stash('user_id'), $self->stash('user_hash') ) ) {
        $self->info( 'User verified: ' . $self->stash('user_id') );
        $self->flash(
            message => {
                type => 'success',
                text => 'Successfully verified this user account. You may now login with your credentials.',
            }
        );
    }
    else {
        $self->flash( message => 'Unable to verify user account using the link provided.' );
    }

    $self->redirect_to('/user/login');
}

sub forgot_password ($self) {
    if ( my $email = $self->param('email') ) {
        try {
            $self->_captcha;

            my $user = CBQ::Model::User->new->load( { email => $email }, 1 );
            if ( $user->data->{active} ) {
                $user->send_email( 'reset_password', $self->url_for('/user/reset_password') );
            }
            else {
                $user->send_email( 'verify_email', $self->url_for('/user/verify') );
            }

            my $email = {
                to   => $user->data->{email},
                from => conf->get( qw( email from ) ),
            };
            $email->{$_} =~ s/(<|>)/ ( $1 eq '<' ) ? '&lt;' : '&gt;' /eg for ( qw( to from ) );

            $self->flash(
                message => {
                    type => 'success',
                    text => join( ' ',
                        'Sent email to: ' .
                            '<b>' . $email->{to} . '</b>.',
                        'Check your email for reception of the email.',
                        'If you don\'t see the email in a couple minutes, ' .
                            'check your spam folder.',
                        'Contact <b>' . $email->{from} . '</b> if you need help.',
                    ),
                }
            );

            $self->redirect_to('/');
        }
        catch ($e) {
            $e =~ s/\s+at\s+(?:(?!\s+at\s+).)*[\r\n]*$//;
            $self->stash( message => $e );
        }
    }
}

sub reset_password ($self) {
    if ( my $passwd = $self->param('passwd') ) {
        try {
            if (
                CBQ::Model::User->new->reset_password(
                    $self->stash('user_id'),
                    $self->stash('user_hash'),
                    $passwd,
                )
            ) {
                $self->info( 'Password reset for: ' . $self->stash('user_id') );
                $self->flash(
                    message => {
                        type => 'success',
                        text => 'Successfully reset password. Login with your new password.',
                    }
                );

                $self->redirect_to('/user/login');
            }
            else {
                $self->stash( message => 'Failed to reset password.' );
            }
        }
        catch ($e) {
            $e =~ s/\s+at\s+(?:(?!\s+at\s+).)*[\r\n]*$//;
            $e =~ s/^"([^""]+)"/ '"' . join( ' ', map { ucfirst($_) } split( '_', $1 ) ) . '"' /e;
            $e =~ s/DBD::\w+::st execute failed:\s*//;
            $e .= '. Please try again.';

            $self->stash( message => $e );
        }
    }
}

sub login ($self) {
    my %params = $self->req->params->to_hash->%*;

    if ( $params{type} and $params{type} eq 'login' ) {
        try {
            my $user = CBQ::Model::User->new->login( map { $self->param($_) } qw( email passwd ) );

            $self->info( 'Login success for: ' . $user->data->{email} );
            $self->session( user_id => $user->id );
            $self->redirect_to('/user/tools');
        }
        catch ($e) {
            if ( $e =~ /\bcaptcha\b/i ) {
                $e =~ s/\s+at\s+(?:(?!\s+at\s+).)*[\r\n]*$//;
                $self->stash( message => $e );
            }
            else {
                $self->info( 'Login failure for ' . $self->param('email') );
                $self->stash( message =>
                    'Login failed. Please try again, or try the ' .
                    '<a href="' . $self->url_for('/user/forgot_password') . '">Forgot Password</a> page.'
                );
            }
        }
    }
}

sub logout ($self) {
    $self->info(
        'Logout requested from: ' .
        ( ( $self->stash('user') ) ? $self->stash('user')->data->{email} : '(Unlogged-in user)' )
    );

    $self->session( user_id => undef );

    $self->flash( message => {
        type => 'notice',
        text => 'You have been logged out.',
    } );

    $self->redirect_to('/');
}

sub tools ($self) {
    my $meeting = CBQ::Model::Meeting->new;

    $self->stash(
        open_meetings => $meeting->open_meetings,
        past_meetings => $meeting->past_meetings( $self->stash('user') ),
        users         => [
            sort {
                $a->{first_name} cmp $b->{first_name} or
                $a->{last_name} cmp $b->{last_name}
            } CBQ::Model::User->new->every_data
        ],
    );
}

{
    ( my $contact_email = conf->get( qw( email from ) ) )
        =~ s/(<|>)/ ( $1 eq '<' ) ? '&lt;' : '&gt;' /eg;

    sub _captcha ($self) {
        my $captcha = $self->param('captcha') // '';
        $captcha =~ s/\D//g;

        die join( ' ',
            'The captcha sequence provided does not match the captcha sequence in the captcha image.',
            'Please try again.',
            'If the problem persists, email <b>' . $contact_email . '</b> for help.',
        ) unless ( $captcha and $self->session('captcha') and $captcha eq $self->session('captcha') );

        delete $self->session->{captcha};
        return;
    }
}

1;

=head1 NAME

CBQ::Control::User

=head1 DESCRIPTION

This class is a subclass of L<Mojolicious::Controller> and provides handlers
for "user" actions.

=head1 METHODS

=head2 sign_up

Handler for new user account sign-up.

=head2 edit

Handler for user data edit.

=head2 verify

Handler for user account verification via email.

=head2 forgot_password

Handler for the forgot password page.

=head2 reset_password

Handler for password reset following a forgot password page submit.

=head2 login

Handler for login.

=head2 logout

Handler for logout.

=head2 tools

Handler for user tools.

=head1 INHERITANCE

L<Mojolicious::Controller>.
