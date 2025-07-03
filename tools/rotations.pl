#!/usr/bin/env perl
use exact -cli;
use Bible::Reference;

my $settings = {
    details   => 0,
    stats     => 1,
    verses_by => 1,
    sort      => 0,
};

my $sets = [
    [
        'Youth: "Minimalist"',
        [
            'John',
            [ 'Hebrews', '1 Peter; 2 Peter' ],
            'Matthew 1:18-25; 2-12; 14-22; 26-28',
            [ 'James', 'Romans' ],
            'Acts 1-20',
            [ 'Galatians', 'Ephesians', 'Philippians', 'Colossians' ],
            'Luke 1-2; 3:1-23; 9-11; 13-19; 21-24',
            '1 Corinthians; 2 Corinthians',
        ],
    ],
    [
        'Youth: "Traditional"',
        [
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
            '1 Corinthians; 2 Corinthians',
        ],
    ],
    [
        'Youth: "Recommended"',
        [
            'John',
            [
                'Hebrews',
                '1 Peter; 2 Peter',
                '1 Timothy; 2 Timothy',
                'Titus',
            ],
            'Matthew 1:18-25; 2-28',
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
            'Luke 1-2; 3:1-23; 4-24',
            '1 Corinthians; 2 Corinthians',
        ],
    ],
    [
        'Youth: "Reduced"',
        [
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
            '1 Corinthians; 2 Corinthians',
        ],
    ],
    [
        'Old Testament Genealogies',
        [
            'Genesis 5; 10; 11:10-32; 25:12-16; 36; 46:8-27',
            'Exodus 6:14-26',
            'Numbers 1:5-44; 26:4-61',
            'Joshua 14-19',
            '1 Chronicles 1-9',
            'Ezra 2; 10:17-44',
            'Nehemiah 7:6-73',
        ],
    ],
    [
        'Adult: "Essential"',
        [
            'Genesis 1-9',
            'Genesis 10-24',
            'Genesis 25-36',
            'Genesis 37-50',
            'Psalm 1-21',
            'Psalm 22-41',
            'Psalm 42-72',
            'Psalm 73-89',
            'Psalm 90-106',
            'Psalm 107-128',
            'Psalm 129-150',
            [
                'Deuteronomy 1-4',
                'Deuteronomy 5-11',
            ],
            'Deuteronomy 12-26',
            'Deuteronomy 27-34',
            'Ezra',
            'Nehemiah',
            'Proverbs 1-9',
            'Proverbs 10-22',
            'Proverbs 23-31',
            [
                'Ecclesiastes',
                'Joel',
            ],
            'Daniel',

        ],
    ],
    [
        'Adult: "Comprehensive"',
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
            [
                'Deuteronomy 1-4',
                'Deuteronomy 5-11',
            ],
            'Deuteronomy 12-26',
            'Deuteronomy 27-34',
            'Joshua 1-12',
            'Joshua 13-24',
            'Judges 1-16',
            [
                'Judges 17-21',
                'Ruth',
            ],
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
            [
                'Ecclesiastes',
                'Song of Songs',
            ],
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
            [
                'Hosea',
                'Joel',
                'Amos',
            ],
            [
                'Obadiah',
                'Jonah',
                'Micah',
                'Nahum',
                'Habakkuk',
            ],
            [
                'Zephaniah',
                'Haggai',
                'Zechariah',
                'Malachi',
            ],
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

=head1 NAME

rotations.pl - Calculate a material rotations analysis report

=head1 SYNOPSIS

    rotations.pl OPTIONS
        -h|help
        -m|man

=head1 DESCRIPTION

This program will calculate a material rotations analysis report.
