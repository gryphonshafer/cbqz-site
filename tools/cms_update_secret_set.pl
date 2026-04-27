#!/usr/bin/env perl
use exact -cli, -conf;
use Crypt::URandom 'urandom';
use CBQ::Model::Region;

my $opt = options( qw{ acronym|a=s save|s } );
pod2usage( 'Region acronym required') unless $opt->{acronym};

try {
    if ( my $region = CBQ::Model::Region->new->load({ acronym => uc $opt->{acronym} }) ) {

        my $secret_db = CBQ::Model::Region::bcrypt( urandom(46) );
        my $secret_gh = CBQ::Model::Region::bcrypt($secret_db);

        $region->save({ secret => $secret_db }) if ( $opt->{save} );

        say '       Region: ', $region->data->{name};
        say '      Acronym: ', $region->data->{acronym};
        say '   Repository: ', 'cbqz-' . lc $opt->{acronym};
        say '  Payload URL: ', 'https://cbqz.org/cms_update/' . conf->get( qw( regional_cms update_suffix ) );
        say 'GitHub Secret: ', $secret_gh;
        say '     Database: ', ( $opt->{save} ) ? 'Saved' : 'NOT SAVED';
    }
}
catch ($e) {
    die deat($e), "\n";
}

=head1 NAME

cms_update_secret_set.pl - Set a region's bcrypt-ed secret and display secret

=head1 SYNOPSIS

    set_region_secret.pl OPTIONS
        -a|acronym ACRONYM  # region's acronym (required)
        -s|save             # flag to save the bcrypt-ed secret to the database
        -h|help
        -m|man

=head1 DESCRIPTION

This program will set a region's bcrypt-ed secret and display the
un-bcrypted-secret with basic settings to use when adding a GitHub Webhook.

=head2 Instructions

In a region's GitHub repository (for example, WWA's GitHub repository is
"cbqz-wwa"), go to Settings, then Webhooks, then click the "Add webhook" button.

"Content type" should be C<application/json>. SSL verification should be
enabled. Trigger the webhook for the C<push> event only. Then use the output of
this program for the other values.
