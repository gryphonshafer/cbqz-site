#!/usr/bin/env perl
use exact;
use Bible::Reference;

my $parts = [
    [
        [  425, 'Mark 1-10' ],
        [  253, 'Mark 11-16' ],
        [  404, 'Revelation' ],
    ],
    [
        [  235, 'Genesis 1-9' ],
        [  424, 'Genesis 10-24' ],
        [  425, 'Genesis 25-36' ],
        [  449, 'Genesis 37-50' ],
        [  335, 'Exodus 1-12' ],
        [  310, 'Exodus 13-23' ],
        [  261, 'Exodus 24-31' ],
        [  307, 'Exodus 32-40' ],
        [  490, 'Leviticus 1-16' ],
        [  369, 'Leviticus 17-27' ],
        [  384, 'Numbers 1-9' ],
        [  387, 'Numbers 10-21' ],
        [  202, 'Numbers 22-27' ],
        [  315, 'Numbers 28-36' ],
        [  161, 'Deuteronomy 1-4' ],
        [  187, 'Deuteronomy 5-11' ],
        [  345, 'Deuteronomy 12-26' ],
        [  266, 'Deuteronomy 27-34' ],
    ],
    [
        [  303, 'Joshua 1-12' ],
        [  355, 'Joshua 13-24' ],
        [  471, 'Judges 1-16' ],
        [  147, 'Judges 17-21' ],
        [   85, 'Ruth' ],
        [  157, '1 Samuel 1-7' ],
        [  191, '1 Samuel 8-14' ],
        [  462, '1 Samuel 15-31' ],
        [  295, '2 Samuel 1-12' ],
        [  400, '2 Samuel 13-24' ],
        [  434, '1 Kings 1-11' ],
        [  385, '1 Kings 12-25' ],
        [  317, '2 Kings 1-11' ],
        [  402, '2 Kings 12-25' ],
        [  407, '1 Chronicles 1-9' ],
        [  267, '1 Chronicles 10-19' ],
        [  268, '1 Chronicles 20-29' ],
        [  201, '2 Chronicles 1-9' ],
        [  249, '2 Chronicles 10-21' ],
        [  372, '2 Chronicles 22-36' ],
    ],
    [
        [  280, 'Ezra' ],
        [  406, 'Nehemiah' ],
        [  167, 'Esther' ],
    ],
    [
        [  369, 'Job 1-15' ],
        [  350, 'Job 16-30' ],
        [  351, 'Job 31-42' ],
        [  265, 'Psalm 1-21' ],
        [  351, 'Psalm 22-41' ],
        [  465, 'Psalm 42-72' ],
        [  358, 'Psalm 73-89' ],
        [  321, 'Psalm 90-106' ],
        [  433, 'Psalm 107-128' ],
        [  268, 'Psalm 129-150' ],
        [  256, 'Proverbs 1-9' ],
        [  388, 'Proverbs 10-22' ],
        [  271, 'Proverbs 23-31' ],
        [  222, 'Ecclesiastes' ],
        [  117, 'Song of Solomon' ],
    ],
    [
        [  464, 'Isaiah 1-24' ],
        [  302, 'Isaiah 25-39' ],
        [  216, 'Isaiah 40-48' ],
        [  310, 'Isaiah 49-66' ],
        [  438, 'Jeremiah 1-17' ],
        [  490, 'Jeremiah 18-36' ],
        [  166, 'Jeremiah 37-44' ],
        [  270, 'Jeremiah 45-52' ],
        [  154, 'Lamentations' ],
        [  216, 'Ezekiel 1-11' ],
        [  403, 'Ezekiel 12-24' ],
        [  230, 'Ezekiel 25-33' ],
        [  424, 'Ezekiel 34-48' ],
        [  357, 'Daniel' ],
    ],
    [
        [  197, 'Hosea' ],
        [   73, 'Joel' ],
        [  146, 'Amos' ],
        [   21, 'Obadiah' ],
        [   48, 'Jonah' ],
        [  105, 'Micah' ],
        [   47, 'Nahum' ],
        [   56, 'Habakkuk' ],
        [   53, 'Zephaniah' ],
    ],
    [
        [   38, 'Haggai' ],
        [  211, 'Zechariah' ],
        [   55, 'Malachi' ],
    ],
];

exit;

my $settings = {
    details   => 0,
    stats     => 0,
    verses_by => 0,
    sort      => 0,
};

my $sets = [
    [
        '"Minimalist"',
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
        '"Traditional"',
        [
            '1 Corinthians; 2 Corinthians',
            'John',
            [ 'Hebrews', '1 Peter; 2 Peter' ],
            'Matthew',
            [ 'James', 'Romans' ],
            'Acts',
            [
                'Galatians', 'Ephesians', 'Philippians', 'Colossians',
                'Philemon',
            ],
            'Luke',
        ],
    ],
    [
        'Skipped Books',
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
        '"Recommended"',
        [
            '1 Corinthians; 2 Corinthians',
            'John',
            [
                'Hebrews',
                '1 Peter; 2 Peter',
                '1 Timothy; 2 Timothy',
                'Titus',
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
                '1 Thessalonians; 2 Thessalonians',
                'Jude',
            ],
            'Luke',
        ],
    ],
    [
        '"Reduced"',
        [
            '1 Corinthians; 2 Corinthians',
            'John',
            [
                'Hebrews',
                '1 Peter; 2 Peter',
                '1 Timothy; 2 Timothy',
                'Titus',
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
                '1 Thessalonians; 2 Thessalonians',
                'Jude',
            ],
            'Luke 1-2; 3:1-23; 9-11; 13-19; 21-24',
        ],
    ],
    [
        'Remnant + Old Testament',
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
            '1 Chronicles 1-9',
            '1 Chronicles 10-19',
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
];

report(@$_) for ( grep { @$_ == 2 } @$sets );

sub report ( $name, $nodes ) {
    my @counts;

    print '>' x 50 . ' ' . $name . "\n\n";

    my $br = Bible::Reference->new;
    my ( $process, $data );
    $process = sub ( $level, $nodes ) {
        my @combined_nodes;
        for my $node (@$nodes) {
            $node = $process->( $level + 1, $node ) if ( ref $node );

            my $refs  = $br->clear->add_detail(0)->in($node)->refs;
            my $count = $br->clear->add_detail(1)->in($node)->as_verses->@*;

            push( @counts, $count ) if ( $level == 0 );
            push( @$data, { level => $level, count => $count, refs => $refs } );
            push( @combined_nodes, $node );
        }
        return join( '; ', @combined_nodes );
    };
    $process->( 0, $nodes );

    $data = [ sort { $a->{count} <=> $b->{count} } @$data ] if ( $settings->{sort} );

    for my $dat (@$data) {
        printf '' . ( ' ' x ( 10 * $dat->{level} ) ) . "%5s <-- %s\n", $dat->{count}, $dat->{refs}
            if ( not $dat->{level} or $settings->{details} );
    }

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
