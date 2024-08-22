#!/usr/bin/env perl
use exact;
use Bible::Reference;

my $settings = {
    details   => 0,
    stats     => 1,
    verses_by => 1,
};

my $sets = [
    [
        '"Minimalist": Current CMA',
        [
            '1 Corinthians; 2 Corinthians',
            'John',
            [ 'Hebrews', '1 Peter; 2 Peter' ],
            'Matthew 1:18-25; 2-12; 14-22; 26-28',
            [ 'James', 'Romans' ],
            'Acts 1-20',
            [ 'Galatians', 'Ephesians', 'Philippians', 'Colossians' ],
            'Luke 1-2; 3:1-23; 9-11; 13-19; 21-24',
        ],
    ],
    [
        # 'Skipped Books',
        [
            'Mark',
            '1 Thessalonians; 2 Thessalonians',
            '1 Timothy; 2 Timothy',
            'Titus',
            '1 John; 2 John; 3 John',
            'Jude',
            'Revelation',
        ],
    ],
    [
        '"Recommended": All Non-CMA Quizzing + Include (Most) Skipped Books',
        [
            [
                '1 Corinthians; 2 Corinthians',
                '1 Thessalonians; 2 Thessalonians',
            ],
            'John',
            [
                'Hebrews', '1 Peter; 2 Peter',
                '1 Timothy; 2 Timothy',
            ],
            'Matthew',
            [
                'James',
                'Romans',
                '1 John; 2 John; 3 John',
            ],
            'Acts',
            [
                'Galatians', 'Ephesians', 'Philippians', 'Colossians',
                'Philemon',
            ],
            'Luke',
        ],
    ],
    [
        '"Reduced": Current CMA + Philemon + Include (Most) Skipped Books',
        [
            [
                '1 Corinthians; 2 Corinthians',
                '1 Thessalonians; 2 Thessalonians',
            ],
            'John',
            [
                'Hebrews', '1 Peter; 2 Peter',
                '1 Timothy; 2 Timothy',
            ],
            'Matthew 1:18-25; 2-12; 14-22; 26-28',
            [
                'James',
                'Romans',
                '1 John; 2 John; 3 John',
            ],
            'Acts 1-20',
            [
                'Galatians', 'Ephesians', 'Philippians', 'Colossians',
                'Philemon',
            ],
            [
                'Luke 1-2; 3:1-23; 9-11; 13-19; 21-24',
                'Luke 12',
            ],
        ],
    ],
    [
        '"Smoothed": Current CMA + Philemon + Include (Most) Skipped Books + Backport Non-Full Books',
        [
            [
                '1 Corinthians; 2 Corinthians',
                '1 Thessalonians; 2 Thessalonians',
            ],
            'John',
            [
                'Hebrews', '1 Peter; 2 Peter',
                '1 Timothy; 2 Timothy',
                'Matthew 1:1-17; 13; 23-25',
            ],
            'Matthew 1:18-25; 2-12; 14-22; 26-28',
            [
                'James',
                'Romans',
                '1 John; 2 John; 3 John',
                'Acts 24-28',
            ],
            [
                'Acts 1-20',
                'Acts 21-23',
            ],
            [
                'Galatians', 'Ephesians', 'Philippians', 'Colossians', 'Philemon',
                'Luke 3:24-38',
                'Luke 4',
                'Luke 5',
                'Luke 6',
                'Luke 7',
                'Luke 8',
                'Luke 20',
            ],
            [
                'Luke 1-2; 3:1-23; 9-11; 13-19; 21-24',
                'Luke 12',
            ],
        ],
    ],
    [
        'Remnant + OT Splits',
        [
            'Mark 1-10',
            'Mark 11-16',
            'Revelation',
            'Genesis 1-9',
            'Genesis 10-24',
            'Genesis 25-36',
            'Genesis 37-50',
            'Exodus 1-12',
            'Exodus 13-23',
            'Exodus 24-31',
            'Exodus 32-40',
            'Leviticus 1-16',
            'Leviticus 17-27',
            'Numbers 1-9',
            'Numbers 10-21',
            'Numbers 22-27',
            'Numbers 28-36',
            'Deuteronomy 1-4',
            'Deuteronomy 5-11',
            'Deuteronomy 12-26',
            'Deuteronomy 27-34',
            'Joshua 1-12',
            'Joshua 13-24',
            'Judges 1-16',
            'Judges 17-21',
            'Ruth',
            '1 Samuel 1-7',
            '1 Samuel 8-14',
            '1 Samuel 15-31',
            '2 Samuel 1-12',
            '2 Samuel 13-24',
            '1 Kings 1-11',
            '1 Kings 12-25',
            '2 Kings 1-11',
            '2 Kings 12-25',
            '1 Chronicles 1-10',
            '1 Chronicles 11-19',
            '1 Chronicles 20-29',
            '2 Chronicles 1-9',
            '2 Chronicles 10-21',
            '2 Chronicles 22-36',
            'Ezra',
            'Nehemiah',
            'Esther',
            'Job 1-15',
            'Job 16-30',
            'Job 31-42',
            'Psalm 1-21',
            'Psalm 22-41',
            'Psalm 42-72',
            'Psalm 73-89',
            'Psalm 90-106',
            'Psalm 107-128',
            'Psalm 129-150',
            'Proverbs 1-9',
            'Proverbs 10-22',
            'Proverbs 23-31',
            'Ecclesiastes',
            'Song of Songs',
            'Isaiah 1-24',
            'Isaiah 25-39',
            'Isaiah 40-48',
            'Isaiah 49-66',
            'Jeremiah 1-17',
            'Jeremiah 18-36',
            'Jeremiah 37-44',
            'Jeremiah 45-52',
            'Lamentations',
            'Ezekiel 1-11',
            'Ezekiel 12-24',
            'Ezekiel 25-33',
            'Ezekiel 34-48',
            'Daniel',
            'Hosea',
            'Joel',
            'Amos',
            'Obadiah',
            'Jonah',
            'Micah',
            'Nahum',
            'Habakkuk',
            'Zephaniah',
            'Haggai',
            'Zechariah',
            'Malachi',
        ],
    ],
    [
        'Remnant + OT',
        [
            'Genesis 1-9; Daniel',
            'Numbers 28-36; Psalm 129-150',
            '2 Chronicles 22-36; Ezekiel 1-11',
            'Psalm 73-89; Ezekiel 25-33',
            'Numbers 10-21; 2 Chronicles 1-9',
            'Genesis 37-50',
            'Deuteronomy 27-34; Psalm 90-106',
            'Job 16-30; Proverbs 1-9',
            '1 Samuel 1-7; 1 Chronicles 1-10',
            'Jeremiah 1-17',
            'Exodus 24-31; Deuteronomy 12-26',
            'Judges 1-16; Nahum',
            'Isaiah 25-39; Amos',
            '2 Kings 1-11; 1 Chronicles 20-29',
            'Lamentations; Ezekiel 34-48',
            'Leviticus 17-27; Isaiah 40-48',
            'Genesis 10-24; Judges 17-21',
            'Deuteronomy 1-4; Nehemiah',
            'Ezekiel 12-24',
            'Psalm 107-128; Micah',
            'Joel; Mark 1-10',
            'Exodus 1-12; Psalm 1-21',
            'Joshua 1-12; 2 Samuel 1-12',
            'Job 31-42; Mark 11-16',
            '1 Samuel 15-31',
            'Jeremiah 18-36; Haggai',
            'Exodus 32-40; Ezra',
            'Ruth; 1 Kings 1-11',
            'Numbers 22-27; 1 Kings 12-25',
            '1 Chronicles 11-19; Psalm 22-41',
            'Psalm 42-72; Jonah',
            'Numbers 1-9; Zechariah',
            'Genesis 25-36',
            'Deuteronomy 5-11; 2 Kings 12-25',
            'Job 1-15; Ecclesiastes',
            'Esther; Proverbs 10-22',
            'Isaiah 49-66; Jeremiah 45-52',
            'Exodus 13-23; Proverbs 23-31',
            'Joshua 13-24; 2 Chronicles 10-21',
            'Isaiah 1-24; Zephaniah',
            '1 Samuel 8-14; 2 Samuel 13-24',
            'Jeremiah 37-44; Revelation',
            'Leviticus 1-16; Obadiah',
            'Song of Solomon; Hosea; Habakkuk; Malachi',
        ],
    ],
];

report(@$_) for ( grep { @$_ == 2 } @$sets );

sub report ( $name, $nodes ) {
    my @counts;

    print '>' x 50 . ' ' . $name . "\n\n";

    my $br = Bible::Reference->new;
    my $process;
    $process = sub ( $level, $nodes ) {
        my @combined_nodes;
        for my $node (@$nodes) {
            $node = $process->( $level + 1, $node ) if ( ref $node );

            my $refs  = $br->clear->add_detail(0)->in($node)->refs;
            my $count = $br->clear->add_detail(1)->in($node)->as_verses->@*;

            push( @counts, $count ) if ( $level == 0 );

            printf '' . ( ' ' x ( 10 * $level ) ) . "%5s <-- %s\n", $count, $refs
                if ( not $level or $settings->{details} );

            push( @combined_nodes, $node );
        }
        return join( '; ', @combined_nodes );
    };
    $process->( 0, $nodes );

    print "\n";
    stats(\@counts) if $settings->{stats};
}

sub stats ($counts) {
    my $total = 0;
    $total += $_ for (@$counts);
    my $mean = $total / @$counts;

    my $sqtotal = 0;
    $sqtotal += ( $mean - $_ ) ** 2 for (@$counts);
    my $std = ( @$counts > 1 ) ? ( $sqtotal / ( @$counts - 1 ) ) ** 0.5 : 0;

    @$counts = sort { $a <=> $b } @$counts;
    my $median = $counts->[ int( @$counts / 2 ) ];

    printf "%10s: %6.1f\n", @$_ for (
        [   'Min.' => $counts->[0]  ],
        [   'Mean' => $mean         ],
        [   'STD.' => $std          ],
        [ 'Median' => $median       ],
        [   'Max.' => $counts->[-1] ],
        [  'Total' => $total        ],
    );

    print "\n";

    if ( $settings->{verses_by} ) {
        print "Mean:\n";
        printf "%3d verses per day\n",  int( $mean / 212 );
        printf "%3d verses per week\n", int( $mean / 212 ) * 7;

        print "\nMax.:\n";
        printf "%3d verses per day\n",  int( $counts->[-1] / 212 );
        printf "%3d verses per week\n", int( $counts->[-1] / 212 ) * 7;

        print "\n";
    }
}
