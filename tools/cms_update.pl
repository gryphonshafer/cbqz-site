#!/usr/bin/env perl
use exact -cli, -conf;
use CBQ::Model::Region;

my $settings = options( qw( key|k=s secret|s=s ) );
$settings->{all} = 1 unless ( $settings->{key} );
my $region = CBQ::Model::Region->new;
$region->debug( $region->cms_update($settings) );

=head1 NAME

cms_update.pl - Update a region's CMS data from its git repository

=head1 SYNOPSIS

    cms_update.pl OPTIONS
        -k|key    ACRONYM  # region's acronym
        -s|secret SECRET   # region's secret (optional)
        -h|help
        -m|man

=head1 DESCRIPTION

This program will update a region's CMS data from its git repository. You can
run it either on a per-region basis or for all regions.

    ./cms_update.pl                         # all regions
    ./cms_update.pl -key wwa                # only the WWA region
    ./cms_update.pl -key wwa -secret secret # checks the secret
