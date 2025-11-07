package CBQ::Control::User;

use exact -conf, 'Mojolicious::Controller';
use CBQ::Model::User;
use CBQ::Model::Meeting;
use CBQ::Model::Org;
use CBQ::Model::Region;

sub _account_common ( $self, $usage = 'sign_up' ) {
    $self->stash(
        usage   => $usage,
        roles   => conf->get('roles'),
        regions => [ sort { $a->{name} cmp $b->{name} } CBQ::Model::Region->every_data ],
        orgs    => CBQ::Model::Org->orgs(
            ( $self->stash->{req_info}{region} ) ? $self->stash->{req_info}{region}{key}: undef
        ),
        ( ( $self->stash('user') ) ? ( org_and_region_ids => $self->stash('user')->org_and_region_ids ) : () ),
    );
    $self->render( template => 'user/account' );
}

sub sign_up ($self) {
    $self->redirect_to( $self->stash('path_part_prefix') . '/' ) if ( $self->stash('user') );

    my %params = $self->req->params->to_hash->%*;

    if ( $params{usage} and $params{usage} eq 'sign_up' ) {
        my @fields = qw( email passwd first_name last_name phone );
        $self->stash( map { $_ => $params{$_} } @fields );

        try {
            die 'Email, password, first and last name, and phone fields must be filled in'
                if ( grep { length $params{$_} == 0 } @fields );

            $self->_captcha_check;

            my $user = CBQ::Model::User->new->create({ map { $_ => $params{$_} } @fields });

            if ( $user and $user->data ) {
                $user->profile(\%params);
                $user->send_email( 'verify_email', $self->url_for('/user/verify') );

                my $email = {
                    to   => $user->data->{email},
                    from => conf->get( qw( email from ) ),
                };
                $email->{$_} =~ s/(<|>)/ ( $1 eq '<' ) ? '&lt;' : '&gt;' /eg for ( qw( to from ) );

                $self->info( 'User create success: ' . $user->id );
                $self->flash(
                    memo => {
                        class   => 'success',
                        message => join( ' ',
                            'Successfully created user with email address: ' .
                                '<b>' . $email->{to} . '</b>.',
                            'Check your email for reception of the verification email.',
                            'If you don\'t see the verification email in a couple minutes, ' .
                                'check your spam folder.',
                            'Contact <b>' . $email->{from} . '</b> if you need help.',
                        ),
                    }
                );
                $self->redirect_to( $self->stash('path_part_prefix') . '/' );
            }
        }
        catch ($e) {
            if ( $e =~ /\bcaptcha\b/i ) {
                $e =~ s/\s+at\s+(?:(?!\s+at\s+).)*[\r\n]*$//;
                $self->stash( memo => { class => 'error', message => $e } );
            }
            else {
                $e =~ s/\s+at\s+(?:(?!\s+at\s+).)*[\r\n]*$//;
                $e =~ s/^"([^""]+)"/ '"' . join( ' ', map { ucfirst($_) } split( '_', $1 ) ) . '"' /e;
                $e =~ s/DBD::\w+::st execute failed:\s*//;
                $e .= '. Please try again.';

                $e = "Value in $1 field is already registered under an existing user account."
                    if ( $e =~ /UNIQUE constraint failed/ );

                $self->info("User create failure: $e");
                $self->stash( memo => { class => 'error', message => $e }, %params );
            }
        }
    }

    $self->_account_common('sign_up');
}

sub view ($self) {
    try {
        $self->stash( view_user => CBQ::Model::User->new->load( $self->stash('user_id') ) );
    }
    catch ($e) {
        $self->flash( memo => {
            class   => 'error',
            message => 'Unable to view user. Try selecting a user from the list.',
        } );
        $self->redirect_to('/user/list');
    }
}

sub edit ($self) {
    my %params = ( $self->stash('user')->data->%*, $self->req->params->to_hash->%* );
    my @fields = qw( email passwd first_name last_name phone );
    $self->stash( map { $_ => $params{$_} } grep { $_ ne 'passwd' } @fields );

    if ( $params{usage} and $params{usage} eq 'edit' ) {
        try {
            $self->stash('user')->data->{$_} = $params{$_} for ( grep { $params{$_} } @fields );
            $self->stash('user')->profile(\%params);

            $self->flash(
                memo => {
                    class   => 'success',
                    message => 'Successfully saved user data.',
                }
            );

            $self->redirect_to( $self->stash('path_part_prefix') . '/' );
        }
        catch ($e) {
            $e =~ s/\s+at\s+(?:(?!\s+at\s+).)*[\r\n]*$//;
            $e =~ s/^"([^""]+)"/ '"' . join( ' ', map { ucfirst($_) } split( '_', $1 ) ) . '"' /e;
            $e =~ s/DBD::\w+::st execute failed:\s*//;
            $e .= '. Please try again.';

            $e = "Value in $1 field is already registered under an existing user account."
                if ( $e =~ /UNIQUE constraint failed/ );

            $self->info("User create failure: $e");
            $self->stash( memo => { class => 'error', message => $e }, %params );
        }
    }

    $self->_account_common('edit');
}

sub verify ($self) {
    if ( my $user_id = CBQ::Model::User->new->verify( $self->stash('token') ) ) {
        $self->info( 'User verified: ' . $user_id );
        $self->flash( memo => {
            class   => 'success',
            message => 'Successfully verified this user account. You may now login with your credentials.',
        } );
    }
    else {
        $self->flash( memo => {
            class   => 'error',
            message => 'Unable to verify user account using the link provided.',
        } );
    }

    $self->redirect_to('/user/login');
}

sub forgot_password ($self) {
    if ( my $email = $self->param('email') ) {
        try {
            $self->_captcha_check;

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
                memo => {
                    class   => 'success',
                    message => join( ' ',
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
            $self->stash( memo => { class => 'error', message => $e } );
        }
    }
}

sub reset_password ($self) {
    if ( my $passwd = $self->param('passwd') ) {
        try {
            if ( my $user_id = CBQ::Model::User->new->reset_password( $self->stash('token'), $passwd ) ) {
                $self->info( 'Password reset for: ' . $user_id );
                $self->flash(
                    memo => {
                        class   => 'success',
                        message => 'Successfully reset password. Login with your new password.',
                    }
                );

                $self->redirect_to('/user/login');
            }
            else {
                $self->stash( memo => { class => 'error', message => 'Failed to reset password.' } );
            }
        }
        catch ($e) {
            $e =~ s/\s+at\s+(?:(?!\s+at\s+).)*[\r\n]*$//;
            $e =~ s/^"([^""]+)"/ '"' . join( ' ', map { ucfirst($_) } split( '_', $1 ) ) . '"' /e;
            $e =~ s/DBD::\w+::st execute failed:\s*//;
            $e .= '. Please try again.';

            $self->stash( memo => { class => 'error', message => $e } );
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
            $self->stash( memo => { class => 'error', message => $e } );
            }
            else {
                $self->info( 'Login failure for ' . $self->param('email') );
                $self->stash( memo => {
                    class   => 'error',
                    message => 'Login failed. Please try again, or try the ' .
                        '<a href="' . $self->url_for('/user/forgot_password') . '">Forgot Password</a> page.'
                } );
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

    $self->flash( memo => {
        class   => 'notice',
        message => 'You have been logged out.',
    } );

    $self->redirect_to('/');
}

sub list ($self) {
    my $users  = [ grep { not $_->data->{info}{dormant} } CBQ::Model::User->new->every->@* ];
    my $region = $self->stash->{req_info}{region};

    $users = [ grep {
        grep { $_ == $region->{id} } $_->org_and_region_ids->{regions}->@*
    } @$users ] if ($region);

    $self->stash(
        roles => conf->get('roles'),
        users => [
            sort {
                $a->{first_name} cmp $b->{first_name} or
                $a->{last_name}  cmp $b->{last_name}
            }
            map {
                +{
                    orgs => $_->orgs,
                    $_->data->%*,
                };
            }
            @$users
        ],
    );
}

{
    ( my $contact_email = conf->get( qw( email from ) ) )
        =~ s/(<|>)/ ( $1 eq '<' ) ? '&lt;' : '&gt;' /eg;

    sub _captcha_check ($self) {
        my $captcha = $self->param('captcha') // '';
        $captcha =~ s/\D//g;

        die join( ' ',
            'The captcha sequence provided does not match the captcha sequence in the captcha image.',
            'Please try again.',
            'If the problem persists, email <b>' . $contact_email . '</b> for help.',
        ) unless ( $self->check_captcha_value($captcha) );

        return;
    }
}

sub become ($self) {
    my $is_admin = $self->stash('user')->is_admin;
    my $user_id  = $self->param('user');

    unless ($user_id) {
        $self->flash( become => 1 ) if ($is_admin);
        $self->redirect_to('/user/list');
    }
    else {
        $self->session(
            user_id     => $user_id,
            was_user_id => $self->stash('user')->id,
        ) if ($is_admin);
        $self->redirect_to('/');
    }
}

sub unbecome ($self) {
    if ( my $was_user_id = delete $self->session->{was_user_id} ) {
        $self->session( user_id => $was_user_id );
    }
    $self->redirect_to('/');
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

=head2 view

Handler for user view page.

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

=head2 list

Handler for users list.

=head2 become

Become a user (if you are an administrator).

=head2 unbecome

Return to your original user if you are an administrator and became someone else.

=head1 INHERITANCE

L<Mojolicious::Controller>.
