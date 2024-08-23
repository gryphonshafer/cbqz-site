# Seasonal Material Rotation

A Bible Quizzing **season** consists of a set of meets, typically though
not necessarily beginning in the autumn and concluding the following spring
or summer. To help foster inter-regional, inter-program, and international
collaboration, CBQ obliges regions to memorize according to a
**seasonal material rotation** specified below.

Regions may select one or more rotation **presets**. There are seperate youth
and adult league rotations. A region may select for their adult leagues an adult
preset, a youth preset, or a combination of adult and youth preset.

Further, regions are encouraged to construct customized material labels or
descriptions (which include reference ranges, weights, and translations)
that optimize for missional outcomes for the season.
While the combined reference ranges with non-zero weights must conform to the
**seasonal material rotation preset**, the construction of the set of ranges
and their weights is up to each region.

## Seasonal Material Rotation Presets

<script>
    const start_year = 2018;
    const rotations  = [
        [
            'Youth',
            [
                [
                    'Recommended',
                    `
                        The "Recommended" preset incorporates the "Traditional" preset
                        (the original preset from the 1940s that includes 16 books)
                        and extends it to 25 books of the New Testament,
                        all but Mark and Revelation.
                    `,
                    [  879, 'John'                                                             ],
                    [  711, 'Hebrews', '1 Peter', '2 Peter', '1 Timothy', '2 Timothy', 'Titus' ],
                    [ 1071, 'Matthew'                                                          ],
                    [  674, 'James', 'Romans', '1 John', '2 John', '3 John'                    ],
                    [ 1007, 'Acts'                                                             ],
                    [
                        689,
                        'Galatians', 'Ephesians', 'Philippians', 'Colossians',
                        '1 Thessalonians', '2 Thessalonians',
                        'Philemon',
                        'Jude',
                    ],
                    [ 1151, 'Luke'                           ],
                    [  694, '1 Corinthians', '2 Corinthians' ],
                ],
                [
                    'Traditional',
                    `
                        The "Traditional" preset includes 16 books of the New Testament in the traditional
                        order, groupings, and rotation from the 1940s. This is what nearly all non-CBQ
                        Bible Quizzing programs use.
                    `,
                    [  879, 'John'                                                            ],
                    [  469, 'Hebrews', '1 Peter', '2 Peter'                                   ],
                    [ 1071, 'Matthew'                                                         ],
                    [  541, 'James', 'Romans'                                                 ],
                    [ 1007, 'Acts'                                                            ],
                    [  528, 'Galatians', 'Ephesians', 'Philippians', 'Colossians', 'Philemon' ],
                    [ 1151, 'Luke'                                                            ],
                    [  694, '1 Corinthians', '2 Corinthians'                                  ],
                ],
                [
                    'Minimalist',
                    `
                        The "Minimalist" preset is starts with the "Traditional" preset and removes portions
                        of material from Matthew, Acts, and Luke.
                    `,
                    [ 879, 'John'                                                ],
                    [ 469, 'Hebrews', '1 Peter', '2 Peter'                       ],
                    [ 860, 'Matthew 1:18-25; 2-12; 14-22; 26-28'                 ],
                    [ 541, 'James', 'Romans'                                     ],
                    [ 741, 'Acts 1-20'                                           ],
                    [ 503, 'Galatians', 'Ephesians', 'Philippians', 'Colossians' ],
                    [ 792, 'Luke 1-2; 3:1-23; 9-11; 13-19; 21-24'                ],
                    [ 694, '1 Corinthians', '2 Corinthians'                      ],
                ],
                [
                    'Reduced',
                    `
                        The "Reduced" preset is a hybrid between the "Minimalist" and "Recommended" presets.
                        It starts with the "Minimalist" preset and adds books included in the "Recommended"
                        preset but not the "Traditional" preset.
                    `,
                    [ 879, 'John'                                                                 ],
                    [ 711, 'Hebrews', '1 Peter', '2 Peter', '1 Timothy', '2 Timothy', 'Titus'     ],
                    [ 860, 'Matthew 1:18-25; 2-12; 14-22; 26-28'                                  ],
                    [ 674, 'James', 'Romans', '1 John', '2 John', '3 John'                        ],
                    [ 741, 'Acts 1-20'                                                            ],
                    [
                        689,
                        'Galatians', 'Ephesians', 'Philippians', 'Colossians',
                        '1 Thessalonians', '2 Thessalonians',
                        'Philemon',
                        'Jude',
                    ],
                    [ 792, 'Luke 1-2; 3:1-23; 9-11; 13-19; 21-24' ],
                    [ 694, '1 Corinthians', '2 Corinthians'       ],
                ],
            ],
        ],
        // [
        //     'Adult',
        //     [
        //         [
        //             'Default',
        //             `
        //                 Default
        //             `,
        //             [ 592, 'Genesis 1-9', 'Daniel'                           ],
        //             [ 583, 'Numbers 28-36', 'Psalm 129-150'                  ],
        //             [ 588, '2 Chronicles 22-36', 'Ezekiel 1-11'              ],
        //             [ 588, 'Psalm 73-89', 'Ezekiel 25-33'                    ],
        //             [ 588, 'Numbers 10-21', '2 Chronicles 1-9'               ],
        //             [ 449, 'Genesis 37-50'                                   ],
        //             [ 587, 'Deuteronomy 27-34', 'Psalm 90-106'               ],
        //             [ 606, 'Job 16-30', 'Proverbs 1-9'                       ],
        //             [ 578, '1 Samuel 1-7', '1 Chronicles 1-10'               ],
        //             [ 438, 'Jeremiah 1-17'                                   ],
        //             [ 606, 'Exodus 24-31', 'Deuteronomy 12-26'               ],
        //             [ 518, 'Judges 1-16', 'Nahum'                            ],
        //             [ 448, 'Isaiah 25-39', 'Amos'                            ],
        //             [ 585, '2 Kings 1-11', '1 Chronicles 20-29'              ],
        //             [ 578, 'Lamentations', 'Ezekiel 34-48'                   ],
        //             [ 585, 'Leviticus 17-27', 'Isaiah 40-48'                 ],
        //             [ 571, 'Genesis 10-24', 'Judges 17-21'                   ],
        //             [ 567, 'Deuteronomy 1-4', 'Nehemiah'                     ],
        //             [ 403, 'Ezekiel 12-24'                                   ],
        //             [ 538, 'Psalm 107-128', 'Micah'                          ],
        //             [ 498, 'Joel', 'Mark 1-10'                               ],
        //         ],
        //         [
        //             'Default 2',
        //             `
        //                 Default 2
        //             `,
        //             [ 600, 'Exodus 1-12', 'Psalm 1-21'                       ],
        //             [ 598, 'Joshua 1-12', '2 Samuel 1-12'                    ],
        //             [ 604, 'Job 31-42', 'Mark 11-16'                         ],
        //             [ 462, '1 Samuel 15-31'                                  ],
        //             [ 528, 'Jeremiah 18-36', 'Haggai'                        ],
        //             [ 587, 'Exodus 32-40', 'Ezra'                            ],
        //             [ 519, 'Ruth', '1 Kings 1-11'                            ],
        //             [ 587, 'Numbers 22-27', '1 Kings 12-25'                  ],
        //             [ 604, '1 Chronicles 11-19', 'Psalm 22-41'               ],
        //             [ 513, 'Psalm 42-72', 'Jonah'                            ],
        //             [ 595, 'Numbers 1-9', 'Zechariah'                        ],
        //             [ 425, 'Genesis 25-36'                                   ],
        //             [ 589, 'Deuteronomy 5-11', '2 Kings 12-25'               ],
        //             [ 591, 'Job 1-15', 'Ecclesiastes'                        ],
        //             [ 555, 'Esther', 'Proverbs 10-22'                        ],
        //             [ 580, 'Isaiah 49-66', 'Jeremiah 45-52'                  ],
        //             [ 581, 'Exodus 13-23', 'Proverbs 23-31'                  ],
        //             [ 604, 'Joshua 13-24', '2 Chronicles 10-21'              ],
        //             [ 517, 'Isaiah 1-24', 'Zephaniah'                        ],
        //             [ 591, '1 Samuel 8-14', '2 Samuel 13-24'                 ],
        //             [ 570, 'Jeremiah 37-44', 'Revelation'                    ],
        //             [ 511, 'Leviticus 1-16', 'Obadiah'                       ],
        //             [ 425, 'Song of Solomon', 'Hosea', 'Habakkuk', 'Malachi' ],
        //         ],
        //     ],
        // ],
    ];

    window.addEventListener( 'load', () => {
        const source = document.querySelector('form.rotation');
        rotations.reverse().forEach( rotation => {
            const target = source.cloneNode(true);
            target.classList.remove('no_display');
            target.querySelector('legend span').textContent = rotation[0];

            const select = target.querySelector('select');
            rotation[1].forEach( preset => {
                const option = document.createElement('option');
                option.text = preset[0];
                select.add(option);
            } );

            const tbody   = target.querySelector('tbody');
            const caption = target.querySelector('caption');
            const years   = target.querySelector('div span');
            const build   = () => {
                while ( tbody.firstChild ) tbody.removeChild( tbody.firstChild );
                const preset = rotation[1].find( preset => preset[0] == select.value );

                years.textContent = preset.length - 2;
                caption.innerHTML = preset[1];

                const rows = structuredClone(preset).splice(2);

                const current_year  = new Date().getFullYear();
                const current_month = new Date().getMonth();

                let year = ( current_month >= 7 ) ? current_year : current_year - 1;
                for ( let i = 0; i < year - start_year; i++ ) {
                    rows.push( rows.shift() );
                }

                rows.forEach( row => {
                    const verses = row.shift();

                    const tr = document.createElement('tr');

                    const season = document.createElement('td');
                    season.textContent = year + '-' + ++year;
                    tr.appendChild(season);

                    const material = document.createElement('td');
                    material.innerHTML = row.map( cell => '<span>' + cell + '</span>' ).join('; ');
                    tr.appendChild(material);

                    const count = document.createElement('td');
                    count.textContent = verses;
                    count.className   = 'right';
                    tr.appendChild(count);

                    tbody.appendChild(tr);
                } );
            };

            select.onchange = build;
            build();

            source.parentNode.insertBefore( target, source.nextSibling );
        } );
        source.remove();
    } );
</script>

<form class="rotation no_display">
    <fieldset>
        <legend><span></span> Presets</legend>
        <label class="left">Preset: <select></select></label>
        <div><span></span>-Year Cycle</div>
        <table>
            <thead>
                <th>Season</th>
                <th>Material Description</th>
                <th>Verses<sup>*</sup></th>
            </thead>
            <tbody></tbody>
            <caption></caption>
        </table>
    </fieldset>
</form>

<sup>*</sup>**Note:** The verse counts presented in the above tables are
approximations, likely to be close, but possibly off by a little depending on
the translations selected.
