#!/usr/bin/env perl
use exact -cli, -conf;
use Bible::Reference;
use Omniframe::Util::Output qw( trim table );

my $opt = options( qw{
    label|l=s@
    range|r=s@
    bracket|b=s@
    weights|w=s@
    acronyms|a
    queries|q=i
} );

pod2usage('At least 2 labels must be provided'     ) unless ( $opt->{label  }->@* >= 2                   );
pod2usage('At least 2 brackets must be provided'   ) unless ( $opt->{bracket}->@* >= 2                   );
pod2usage('Labels count must match ranges count'   ) unless ( $opt->{label  }->@* == $opt->{range  }->@* );
pod2usage('Brackets count must match weights count') unless ( $opt->{bracket}->@* == $opt->{weights}->@* );
for ( $opt->{weights}->@* ) {
    $_ = [ grep { defined } map { 0 + $_ } split(/\s+/) ];
    pod2usage('Weight parts counts must all match labels counts') unless ( $opt->{label}->@* == @$_ );
}

$opt->{queries} ||= 12;

my $bref        = Bible::Reference->new;
my @labels      = $opt->{label}->@*;
my $seen_verses = {};
my $lists       = [ map {
    $bref->clear->in($_);
    +{
        label    => trim shift @labels,
        refs     => $bref->add_detail(0)->acronyms(0)->refs,
        verses   => scalar $bref->add_detail(1)->acronyms(0)->as_verses,
        chapters => [ map {
            my $list_verses = $bref->clear->in($_)->add_detail(1)->acronyms(0)->as_verses;
            ( my $verse_list_set = $bref->refs ) =~ s/.*://;
            ( my $chapter = $_ ) =~ s/:.*//;
            my $chapter_verses = $bref->clear->in($chapter)->add_detail(1)->acronyms(0)->as_verses;
            my $exclusive = grep { not $seen_verses->{$_} } @$list_verses;
            $seen_verses->{$_}++ for (@$list_verses);

            +{
                chapter        => $chapter,
                chapter_verses => $chapter_verses,
                chapter_count  => scalar @$chapter_verses,
                list_verse_set => $verse_list_set,
                list_verses    => $list_verses,
                list_count     => scalar @$list_verses,
                exclusive      => $exclusive,
            };
        } $bref->add_detail(0)->acronyms( $opt->{acronyms} )->as_chapters ],
    };
} $opt->{range}->@* ];

my $brackets = [ map {
    my @labels = $opt->{label}->@*;
    +{
        name    => trim $_,
        weights => [ map {
            map { +{
                label  => shift @labels,
                weight => $_,
            } } @$_
        } shift $opt->{weights}->@* ],
    };
} $opt->{bracket}->@* ];

print "# Club Lists and Weights\n\n";

print "## Club Lists\n\n";
say 'Club lists are published lists of verses that will have queries asked from them more frequently.';
say 'The full material for the season is: **', $lists->[-1]{refs}, '**.';
for my $list (@$lists) {
    print
        "\n",
        '### "', $list->{label}, '"', "\n\n",
        '*', $list->{refs}, '*', "\n\n";

    my $cols = [
        'chapter',
        [ 'chapter_count', 'Total #' ],
        [ 'list_verse_set', $list->{label} . ' Verse List' ],
        [ 'list_count', 'Club #' ],
    ];
    push( @$cols, 'exclusive' ) if ( state $loop++ );

    say table(
        rows => $list->{chapters},
        cols => $cols,
    );
}

print "\n";

print "## Weights\n\n";
say 'The following are the current weights of lists per bracket. These weights may be adjusted mid-season.';
for my $bracket (@$brackets) {
    print "\n", '### ', $bracket->{name}, ' Bracket Weights', "\n\n";

    my ( $total_weight, $percent_sums, $i, $k );

    my $lists_counts = [ map { scalar $_->{verses}->@* } @$lists ];
    my $lists_rows   = [
        map {
            my $row = $_;
            $row->{weight_percent} = sprintf( '%0.1f%%', $row->{weight_value} / $total_weight * 100 );

            $i++;
            for my $j ( @$lists_counts[ 0 .. $i - 1 ] ) {
                my $value =
                    $row->{ $j . '_count' } / $lists_counts->[ $i - 1 ] *
                    $row->{weight_value} / $total_weight * 100;
                $row->{ $j . '_percent' } = sprintf( '%0.1f%%', $value );
                $percent_sums->{ $j . '_percent' } += $value;
            }

            $row;
        }
        map {
            $k++;
            my $weight_value = $bracket->{weights}[ $k - 1 ]{weight};
            $total_weight += $weight_value;

            my $j = 0;
            +{
                label        => $_->{label},
                weight_value => $weight_value,
                (
                    map {
                        $j++;
                        ( $_ . '_count' ) =>
                            $lists_counts->[ $j - 1 ] -
                            ( ( $j > 1 ) ? $lists_counts->[ $j - 2 ] : 0 );
                    } @$lists_counts[ 0 .. $k - 1 ]
                ),
            };
        }
        @$lists
    ];

    say table(
        rows => [
            @$lists_rows,
            {
                weight_value => $total_weight,
                map { $_ => sprintf( '%0.1f%%', $percent_sums->{$_} ) } keys %$percent_sums,
            },
            {
                map { $_ => sprintf( '%0.1f',
                    $opt->{queries} * $percent_sums->{$_} / 100
                ) } keys %$percent_sums
            },
        ],
        cols => [
            'label',
            ( map { [ $_ . '_count', 'r', $_ ] } @$lists_counts ),
            [ 'weight_value', 'Weight #' ],
            [ 'weight_percent', 'r', 'Weight %' ],
            ( map { [ $_ . '_percent', 'r', $_ ] } @$lists_counts ),
        ],
    );
}

=head1 NAME

lists_report.pl - Build a club lists Markdown report given labels and weights

=head1 SYNOPSIS

    lists_report.pl OPTIONS
        -l, --label    LIST_LABEL                  # multiple expected
        -r, --range    REFERENCE_RANGE             # multiple expected
        -b, --bracket  BRACKET_NAME                # multiple expected
        -w, --weights  STRING_OF_WEIGHTS           # multiple expected
        -a, --acronyms
        -q, --queries  NUMBER_OF_QUERIES_PER_QUIZ  # default: 12
        -h, --help
        -m, --man

=head1 DESCRIPTION

This program will build a club lists Markdown report given labels and weights.

=head2 -l, --label

Pass some number of list labels (in order). The count of these needs to match
the count of ranges. For example:

    lists_report.pl \
        -l 'Club 100' \
        -l 'Club 300' \
        -l 'Full Material'

=head2 -r, --range

Pass some number of ranges (in order). The count of these needs to match the
count of labels. For example:

    lists_report.pl \
        -r 'John 1:1-14; 3:1-8, 13-17; 4:8-14' \
        -r 'John 1:1-14; 3:1-21; 4:1-26; 6:35-59' \
        -r 'John 1-4; 5:1-3, 5-6'

=head2 -b, --bracket

Pass some number of bracket names (in order). The count of these needs to match
the count of weights. For example:

    lists_report.pl \
        -b 'Preliminary' \
        -b 'Auxiliary' \
        -b 'Top 9'

=head2 -w, --weights

Pass some number of weight sets per bracket names (in order). The weights for
each label in each set are space-separated. The count of these needs to match
the count of brackets, and there needs to be 1 weight per label in each set.
For example:

    lists_report.pl \
        -w '2 3 3' \
        -w '1 1 1' \
        -w '1 2 3'

=head2 -a, --acronyms

A flag that if set will cause the chapter columns in tables to use book acronyms
instead of the full book name.

=head2 -q, --queries

Set the number of queries per quiz. Defaults to 12.
