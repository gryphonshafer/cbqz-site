#!/usr/bin/env perl
use exact -cli, -conf;
use CBQ::Model::Region;
use CBQ::Model::Registration;
use CBQ::Model::User;
use Omniframe::Class::Email;

my $settings = options( qw( id|i=i email|e=s force|f loud|l ) );

my $reg   = CBQ::Model::Registration->new;
my $email = Omniframe::Class::Email->new( type => 'registration_reminder' );
$email->log_level('warning') unless ( $settings->{loud} );
( my $from_email = conf->get( qw( email from ) ) ) =~ s/^[^<]*<([^>]+)>.*$/$1/;

for my $reminder_meet ( CBQ::Model::Region->new->reminder_meets->@* ) {
    my $coach_user_ids = ( $settings->{id} )
        ? [ $settings->{id} ]
        : $reg->coach_user_ids( $reminder_meet->{region}{id} );
    next unless (@$coach_user_ids);

    for my $user ( map { CBQ::Model::User->new->load($_) } @$coach_user_ids ) {
        my $reg_data = $reg->get_reg( $reminder_meet->{region}{id}, $user );

        for my $o ( reverse 0 .. $reg_data->{orgs}->@* - 1 ) {
            for my $t ( reverse 0 .. $reg_data->{orgs}[$o]{teams}->@* - 1 ) {
                for my $q ( reverse 0 .. $reg_data->{orgs}[$o]{teams}[$t]->@* - 1 ) {
                    splice( $reg_data->{orgs}[$o]{teams}[$t]->@*, $q, 1 )
                        if ( not $reg_data->{orgs}[$o]{teams}[$t][$q]{attend} );
                }
                splice( $reg_data->{orgs}[$o]{teams}->@*, $t, 1 )
                    if ( not $reg_data->{orgs}[$o]{teams}[$t]->@* );
            }
            delete $reg_data->{orgs}[$o]{teams}
                if ( not $reg_data->{orgs}[$o]{teams}->@* );

            for my $n ( reverse 0 .. $reg_data->{orgs}[$o]{nonquizzers}->@* - 1 ) {
                splice( $reg_data->{orgs}[$o]{nonquizzers}->@*, $n, 1 )
                    if ( not $reg_data->{orgs}[$o]{nonquizzers}[$n]{attend} );
            }
            delete $reg_data->{orgs}[$o]{nonquizzers}
                if ( not $reg_data->{orgs}[$o]{nonquizzers}->@* );
        }

        $email->send({
            to => (
                $settings->{email} //
                sprintf( '%s %s <%s>', map { $user->data->{$_} } qw( first_name last_name email ) )
            ),
            data => {
                user       => $user->data,
                meet       => $reminder_meet,
                reg_data   => $reg_data,
                from_email => $from_email,
            },
        });
    }
}

=head1 NAME

registration_reminder.pl - Send registration reminder emails to coaches

=head1 SYNOPSIS

    registration_reminder.pl OPTIONS
        -i|id    USER_ID  # user ID to send to (for testing)
        -e|email EMAIL    # override email address (for testing)
        -l|loud           # skips setting log level to warning
        -f|force          # if set, will skip "reminder day" check
        -h|help
        -m|man

=head1 DESCRIPTION

This program will send registration reminder emails to coaches. For any user
account that's active that either has the profile role of "Coach" or has a most
recent meet registration that included a role of "Coach", the user will get an
email generated and sent to them that includes the current registration data.

Should a user ID be provided, only email for that user will be sent. Should an
email be provided, all email will be sent to that address. And should "force" be
applied, the normal check of if the current day is a "reminder day" is skipped.

Thus, you probably want to run tests with one of the following:

    registration_reminder.pl -f -i 1
    registration_reminder.pl -f -e example@example.com
