#!/usr/bin/env perl
use exact -conf;
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
    [ 'BBQ', 'Burley Bible Quizzing',        '14687 Olympic Dr SE, Port Orchard WA 98367' ],
    [ 'HCC', 'Highlands Community Church',   '3031 NE Tenth St, Renton WA 98056'          ],
    [ 'LH',  'Lighthouse Christian Center',  '3409 23rd St SW, Puyallup WA 98373'         ],
    [ 'ELK', 'Elk Plain Community Church',   '4115 224th St E, Spanaway WA 98387'         ],
    [ 'MAD', 'Juniper Community Church',     '976 S Adams Dr, Madras OR 97741'            ],
    [ 'REM', 'Fruitland Community Church',   '6252 Fruitland Rd NE, Salem OR 97317'       ],
    [ 'IPC', 'Immanuel Presbyterian Church', '405 N William St, Post Falls ID 83854'      ],
);

$sth = $dq->sql(q{
    INSERT OR IGNORE INTO org_region ( org_id, region_id )
    SELECT
        ( SELECT org_id FROM org WHERE acronym = ? ) AS org_id,
        ( SELECT region_id FROM region WHERE acronym = ? ) AS region_id
});
$sth->run(@$_) for (
    [ 'BBQ', 'WWA' ],
    [ 'BBQ', 'OR'  ],
    [ 'HCC', 'WWA' ],
    [ 'LH',  'WWA' ],
    [ 'ELK', 'WWA' ],
    [ 'MAD', 'WWA' ],
    [ 'MAD', 'OR'  ],
    [ 'REM', 'WWA' ],
    [ 'REM', 'OR'  ],
    [ 'IPC', 'WWA' ],
    [ 'IPC', 'INW' ],
);
