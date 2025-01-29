package CBQ::Model::User;

use exact -class, -conf;
use Email::Address;
use Mojo::JSON qw( encode_json decode_json );
use Omniframe::Class::Email;

with qw( Omniframe::Role::Bcrypt Omniframe::Role::Model );

class_has active => 1;

my $min_passwd_length = 8;
my $user_hash_length  = 12;

before 'create' => sub ( $self, $params ) {
    $params->{active} //= 0;
};

sub freeze ( $self, $data ) {
    if ( $self->is_dirty( 'email', $data ) or not exists $data->{email} ) {
        my ($address) = Email::Address->parse( $data->{email} );
        croak('Email not provided properly') unless ($address);
        $data->{email} = lc $address->address;
    }

    if ( $self->is_dirty( 'passwd', $data ) ) {
        croak("Password supplied is not at least $min_passwd_length characters in length")
            unless ( length $data->{passwd} >= $min_passwd_length );
        $data->{passwd} = $self->bcrypt( $data->{passwd} );
    }

    if ( $self->is_dirty( 'phone', $data ) ) {
        $data->{phone} =~ s/\D+//g;
        croak('Phone supplied is not at least 10 digits in length') unless ( length $data->{phone} >= 10 );
    }

    $data->{info} = encode_json( $data->{info} );
    undef $data->{info} if ( $data->{info} eq '{}' or $data->{info} eq 'null' );

    return $data;
}

sub thaw ( $self, $data ) {
    $data->{info} = ( defined $data->{info} ) ? decode_json( $data->{info} ) : {};
    return $data;
}

sub send_email ( $self, $type, $url ) {
    croak('User object not data-loaded') unless ( $self->id );

    push( @{ $url->path->parts }, $self->id, substr( $self->data->{passwd}, 0, $user_hash_length ) );

    return Omniframe::Class::Email->new( type => $type )->send({
        to   => sprintf( '%s %s <%s>', map { $self->data->{$_} } qw( first_name last_name email ) ),
        data => {
            user => $self->data,
            url  => $url->to_abs->to_string,
        },
    });
}

sub verify ( $self, $user_id, $user_hash ) {
    my $user_found = length $user_hash == $user_hash_length and $self->dq->sql(q{
        SELECT COUNT(*) FROM user WHERE user_id = ? AND passwd LIKE ?
    })->run( $user_id, $user_hash . '%' )->value > 0;

    $self->dq->sql('UPDATE user SET active = 1 WHERE user_id = ?')->run($user_id) if $user_found;
    return $user_found;
}

sub reset_password ( $self, $user_id, $user_hash, $new_password ) {
    croak("Password supplied is not at least $min_passwd_length characters in length")
        unless ( length $new_password >= $min_passwd_length );

    my $user_found = length $user_hash == $user_hash_length and $self->dq->sql(q{
        SELECT COUNT(*) FROM user WHERE user_id = ? AND passwd LIKE ?
    })->run( $user_id, $user_hash . '%' )->value > 0;

    return 0 unless $user_found;

    $self->dq->sql('UPDATE user SET passwd = ? WHERE user_id = ?')
        ->run( $self->bcrypt($new_password), $user_id );

    return 1;
}

sub login ( $self, $email, $passwd ) {
    $self->load({
        email  => lc($email),
        passwd => $self->bcrypt($passwd),
        active => 1,
    });

    $self->save({ last_login => \q/( STRFTIME( '%Y-%m-%d %H:%M:%f', 'NOW', 'LOCALTIME' ) )/ });

    return $self;
}

sub is_qualified_delegate ($self) {
    return 1 if (
        $self->dq->sql( q{
            SELECT COUNT(*) FROM meeting WHERE start <= DATETIME('NOW')
        } )->run->value < 4 and
        grep { $_ eq $self->data->{email} }
        map { /<([^>]+)>/ }
        ( conf->get('pre_qualified_delegates') // [] )->@*
    );

    my $attendance = $self->dq->sql( q{
        SELECT COUNT(*)
        FROM (
            SELECT m.meeting_id, um.user_id
            FROM meeting AS m
            LEFT JOIN user_meeting AS um ON m.meeting_id = um.meeting_id AND um.user_id = ?
            ORDER BY m.start DESC
            LIMIT ?
        )
        WHERE user_id
    } )->run( $self->id, 4 )->value;

    return ( $attendance >= 3 ) ? 1 : 0;
}

1;

=head1 NAME

CBQ::Model::User

=head1 SYNOPSIS

    use CBQ::Model::User;

    my $user_id = CBQ::Model::User->new->create({
        email      => 'email',
        passwd     => 'passwd',
        first_name => 'first_name',
        last_name  => 'last_name',
        phone      => 'phone', # optional
        info       => {},      # optional
    })->id;

    my $user = CBQ::Model::User->new->login( 'username', 'passwd' );

    use Mojo::URL;
    $user->send_email( 'verify_email',    Mojo::URL->new );
    $user->send_email( 'forgot_password', Mojo::URL->new );

    $user->verify( 42, 'a1b2c3d4' );
    $user->reset_password( 42, 'a1b2c3d4', 'new_password' );

    my $logged_in_user = CBQ::Model::User->new->login( 'username', 'passwd' );

=head1 DESCRIPTION

This class is the model for user objects. A user is an individual person that
uses the application.

=head1 EXTENDED METHOD

=head2 create

Extended from L<Omniframe::Role::Model>, this method requires C<email>,
C<passwd>, C<first_name>, and C<last_name> values.

This method can optionally accept a C<info> hashref.

=head1 OBJECT METHODS

=head2 freeze

Likely not used directly, this method is provided such that
L<Omniframe::Role::Model> will ensure a valid email address, which is checked
via L<Email::Address>, and and a phone number.

Also, it will C<bcrypt> passwords before storing them in the database. It
expects a hashref of values and will return a hashref of values with the
C<passwd> crypted.

Also, C<freeze> will JSON-encode the C<info> hashref.

=head2 thaw

Likely not used directly, C<thaw> will JSON-decode the C<info> hashref.

=head2 send_email

This method will send an email to the user of a particular type. It requires an
email template for the type. This method must be provided the type and a loaded
L<Mojo::URL> object to redirect the user back to.

    use Mojo::URL;
    $user->send_email( 'verify_email',    Mojo::URL->new );
    $user->send_email( 'forgot_password', Mojo::URL->new );

=head2 verify

Response to a verify response from a verify email. Requires a user ID and a
user hash, which is the first set of characters from the user's encrypted
password.

    $user->verify( 42, 'a1b2c3d4' );

=head2 reset_password

Handle a reset password request (from an email). Requires a user ID, a
user hash, which is the first set of characters from the user's encrypted
password, and the new password to set.

    $user->reset_password( 42, 'a1b2c3d4', 'new_password' );

=head2 login

This method requires a username and password string inputs. It will then attempt
to find and login the user. If successful, it will return a loaded user object.

    my $logged_in_user = CBQ::Model::User->new->login( 'username', 'passwd' );

=head2 is_qualified_delegate

Returns true if the user is a qualified delegate as defined by attendance
(viewing) of 3 of the last 4 meetings.

=head1 WITH ROLES

L<Omniframe::Role::Bcrypt>, L<Omniframe::Role::Model>.
