#!/usr/bin/env perl
use exact -conf, -cli;
use CBQ::Model::Region;

my $dq = CBQ::Model::Region->new->dq;

$dq->sql( 'DELETE FROM ' . $_ )->run for ( qw( org_region org region ) );

my $sth = $dq->sql('INSERT OR IGNORE INTO region ( acronym, name ) VALUES ( ?, ? )');
$sth->run(@$_) for (
    [ 'WWA', 'Western Washington' ],
    [ 'OR',  'Oregon'             ],
    [ 'INW', 'Inland Northwest'   ],
);

$sth = $dq->sql('INSERT OR IGNORE INTO org ( acronym, name, address ) VALUES ( ?, ?, ? )');
$sth->run(@$_) for (
    [ 'EBC',  'Eastridge Baptist Church',     '12520 SE 240th St, Kent WA 98031'            ],
    [ 'LH',   'Lighthouse Christian Center',  '3409 23rd St SW, Puyallup WA 98373'          ],
    [ 'ELK',  'Elk Plain Community Church',   '4115 224th St E, Spanaway WA 98387'          ],
    [ 'GIG',  'Gig Harbor Bible Quizzing',    'Gig Harbor WA'                               ],
    [ 'KVBC', 'Kent Vietnamese Bible Church', '24511 104th Ave SE, Kent WA 98030'           ],
    [ 'BBQ',  'Burley Bible Quizzing',        '14687 Olympic Dr SE, Port Orchard WA 98367'  ],
    [ 'HCC',  'Highlands Community Church',   '3031 NE Tenth St, Renton WA 98056'           ],

    [ 'MAD',  'Juniper Community Church',     '976 S Adams Dr, Madras OR 97741'             ],
    [ 'RBQ',  'Fruitland Community Church',   '6252 Fruitland Rd NE, Salem OR 97317'        ],
    [ 'MED',  'First Church of God',          '2000 Crater Lake Ave., Medford OR 97504'     ],
    [ 'RWC',  'River West Church',            '2000 Country Club Rd., Lake Oswego OR 97034' ],

    [ 'IPC', 'Immanuel Presbyterian Church', '405 N William St, Post Falls ID 83854'        ],
    [ 'GBC', 'Grace Bible Church',           "152 W Prairie Ave, Coeur d'Alene ID 83815"    ],
    [ 'GRV', 'Grangeville Bible Quizzing',   'Grangeville ID'                               ],
    [ 'KMH', 'Kamiah Bible Quizzing',        'Kamiah ID'                                    ],
);

$sth = $dq->sql(q{
    INSERT OR IGNORE INTO org_region ( org_id, region_id )
    SELECT
        ( SELECT org_id FROM org WHERE acronym = ? ) AS org_id,
        ( SELECT region_id FROM region WHERE acronym = ? ) AS region_id
});
$sth->run(@$_) for (
    [ 'EBC',  'WWA' ],
    [ 'LH',   'WWA' ],
    [ 'ELK',  'WWA' ],
    [ 'GIG',  'WWA' ],
    [ 'KVBC', 'WWA' ],
    [ 'BBQ',  'WWA' ],
    [ 'HCC',  'WWA' ],

    [ 'MAD',  'OR' ],
    [ 'RBQ',  'OR' ],
    [ 'MED',  'OR' ],
    [ 'RWC',  'OR' ],

    [ 'IPC', 'INW' ],
    [ 'GBC', 'INW' ],
    [ 'GRV', 'INW' ],
    [ 'KMH', 'INW' ],
);

=head1 NAME

cms_db_populate.pl - Migrate database to full CMSness

=head1 SYNOPSIS

    cms_db_populate.pl OPTIONS
        -h|help
        -m|man

=head1 DESCRIPTION

This program will migrate database to full CMSness.
