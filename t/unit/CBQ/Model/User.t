use Test2::V0;
use Mojo::URL;
use exact -conf;
use CBQ::Model::User;

my $obj;
ok( lives { $obj = CBQ::Model::User->new }, 'new' ) or note $@;
DOES_ok( $obj, 'Omniframe::Role::Model' );
can_ok( $obj, qw(
    active
    create
    freeze thaw
    send_email verify reset_password login is_qualified_delegate
) );

$obj->dq->begin_work;

like(
    dies { $obj->create({}) },
    qr/Email not provided properly/,
    'create({})',
);

( my $username = lc( crypt( $$ . ( time + rand ), 'gs' ) ) ) =~ s/[^a-z0-9]+//g;
my $email = $username . '@example.com';

like(
    dies { $obj->create({ email => 'bad_email' }) },
    qr/Email not provided properly/,
    q/create({ email => 'bad_email' })/,
);

like(
    dies { $obj->create({
        email      => $email,
        passwd     => 'short',
        first_name => 'first_name',
        last_name  => 'last_name',
    }) },
    qr/Password supplied is not at least/,
    q/create({ passwd => 'short' })/,
);

like(
    dies { $obj->create({
        email      => $email,
        passwd     => 'terrible_but_long_password',
        first_name => 'first_name',
        last_name  => 'last_name',
        phone      => 'short',
    }) },
    qr/Phone supplied is not at least/,
    q/create({ phone => 'short' })/,
);

ok(
    lives { $obj->create({
        email      => $email,
        passwd     => 'terrible_but_long_password',
        first_name => 'first_name',
        last_name  => 'last_name',
        phone      => '1234567890',
    }) },
    q{create({...})},
) or note $@;

my $email_obj  = Omniframe::Class::Email->new( type => 'verify_email' );
my $mock_email = mock 'Omniframe::Class::Email' => (
    override => [
        new  => sub { $email_obj },
        send => sub { @_ },
    ]
);

ok(
    lives { $obj->send_email( 'verify_email', Mojo::URL->new('http://localhost:3000') ) },
    q/send_email(...)/,
) or note $@;

ok(
    $obj->verify( $obj->id, substr( $obj->data->{passwd}, 0, 12 ) ),
    q/verify(...)/,
);

ok(
    $obj->reset_password( $obj->id, substr( $obj->data->{passwd}, 0, 12 ), 'new_password' ),
    q/reset_password(...)/,
);

$obj->load( $obj->id );

like(
    dies { $obj->login( $email, 'bad_password' ) },
    qr/Failed to load user/,
    q/login(...) with bad password/,
);

ok(
    $obj->login( $email, 'new_password' ),
    q/login(...) with good password/,
);

is( $obj->is_qualified_delegate, 0, 'is_qualified_delegate' );

$obj->dq->rollback;

done_testing;
