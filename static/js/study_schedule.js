( () => {
    const template_url     = new URL( document.currentScript.src );
    template_url.pathname  = '/html/study_schedule.html';
    const template_promise = fetch(template_url).then( response => response.text() );

    const url         = new URL( window.location.href );
    const cookie_name = url.host + url.pathname;

    function date_display(date) {
        return date.toLocaleDateString( 'en-US', {
            weekday: 'short',
            month  : 'short',
            day    : 'numeric',
        } );
    }

    function display_table_data( data, select_values ) {
        const block_name = select_values.shift();

        return {
            columns: [
                'Week Start',
                'Week End',
                ...data.blocks[block_name].flatMap( block => [ block.name, 'Vs.' ] ),
                ...( ( data.blocks[block_name].length == 1 ) ? [
                    'Sum',
                    'Total',
                ] : [] ),
                'Meet / Label',
            ],
            sets: select_values.map( select_value => {
                const date_cursor = new Date( data['Meet Dates'].at(-1)['Date'] );
                date_cursor.setDate(
                    date_cursor.getDate() -
                    (
                        data['Meet Dates'].length +
                        Math.max(
                            ...Object.values( data.blocks[block_name] ).map( block => block.body.length )
                        ) +
                        parseInt(select_value)
                    ) * 7 + 1
                );

                const set = [];

                let material_i           = 0;
                let sum_verses_to_meet   = 0;
                let total_verses_to_date = 0;

                while ( date_cursor <= data['Meet Dates'].at(-1)['Date'] ) {
                    const date_week_end = new Date(date_cursor);
                    date_week_end.setDate( date_week_end.getDate() + 6 );
                    const row = {
                        week_start: new Date(date_cursor),
                        week_end  : date_week_end,
                    };

                    const meet = data['Meet Dates'].find( meet =>
                        meet['Date'] >= date_cursor &&
                        meet['Date'] <= date_week_end
                    );
                    if (meet) row.meet = meet;

                    const christmas = new Date(date_cursor);
                    christmas.setMonth(11);
                    christmas.setDate(25);
                    const is_christmas = christmas >= date_cursor && christmas <= date_week_end;
                    if (is_christmas) row.is_christmas = true;

                    if (
                        ! meet && ! is_christmas ||
                        meet && meet['Name'] == 'Scramble'
                    ) {
                        const material = data.blocks[block_name][0].body[ material_i++ ];
                        if (material) {
                            row.material = material;

                            sum_verses_to_meet   += Number( material['Verses'] );
                            total_verses_to_date += Number( material['Verses'] );

                            row.sum_verses_to_meet   = sum_verses_to_meet;
                            row.total_verses_to_date = total_verses_to_date;
                        }
                    }
                    if ( meet && meet['Name'] != 'Scramble' ) sum_verses_to_meet = 0;

                    set.push(row);
                    date_cursor.setDate( date_cursor.getDate() + 7 );
                }

                return set;
            } )
        };
    }

    function build_display_table( data, div, event ) {
        const saved_settings     = ( ! event ) ? omniframe.cookies.get(cookie_name) : null;
        let changed_scheduled_by = false;

        if (saved_settings) {
            const schedule_by = div.querySelector('form fieldset label select.schedule_by');
            if ( schedule_by.value != saved_settings[0] ) {
                schedule_by.value    = saved_settings[0];
                changed_scheduled_by = true;
            }
        }

        // clean and setup selects
        if ( event?.target.className == 'schedule_by' || changed_scheduled_by ) {
            const select_labels = div.querySelectorAll('form fieldset label:not(:first-child)');
            for ( let i = select_labels.length - 1; i > 0; i-- ) {
                select_labels[i].remove();
            }
            select_labels[0].querySelector('span')  .textContent   = 'Week Offset:';
            select_labels[0].querySelector('select').selectedIndex = 0;

            const schedule_by = div.querySelector('select').value;
            if ( data.blocks[schedule_by].length > 1 ) {
                const select_labels_parent = select_labels[0].parentNode;
                const node_template        = select_labels[0].cloneNode(true);

                select_labels[0].remove();

                data.blocks[schedule_by].forEach( set => {
                    const node = node_template.cloneNode(true);
                    node.querySelector('span').textContent = set.name + ' Week Offset:';
                    select_labels_parent.appendChild(node);
                } );
            }
        }

        if (saved_settings) div
            .querySelectorAll('form fieldset label:not(:first-child) select')
            .forEach( ( select, index ) => select.value = saved_settings[ index + 1 ] );

        if (event) omniframe.cookies.set(
            cookie_name,
            [ ...div.querySelectorAll('form fieldset label select') ].map( select => select.value ),
            365,
        );

        const data_to_render = display_table_data(
            data,
            [ ...div.querySelectorAll('select') ].map( select => select.value ),
        );

        const table = div.querySelector('table');
        const thead = table.querySelector('thead');
        const tbody = table.querySelector('tbody');

        [ thead, tbody ].forEach( node => {
            while ( node.firstChild ) {
                node.removeChild( node.firstChild );
            }
        } );

        const tr = thead.insertRow();
        data_to_render.columns.forEach( label => tr.appendChild(
            Object.assign( document.createElement('th'), { textContent: label } )
        ) );

        [
            ...new Map(
                data_to_render.sets.flat().map( item => [ item.week_start.getTime(), item.week_start ] )
            ).values()
        ].sort( ( a, b ) => a - b ).forEach( week_start => {
            const items = data_to_render.sets.flatMap( set => {
                const matches = set.filter( item => item.week_start.getTime() == week_start.getTime() );
                return ( matches.length ) ? matches : null;
            } );

            const meet = items.map( item => item && item.meet )[0];

            const tr = tbody.insertRow();
            [
                date_display(week_start),
                date_display( items.find( item => item ).week_end ),

                ...items.flatMap( item => {
                    const extra_verse_counts = ( data_to_render.sets.length == 1 ) ? [
                        ( item && item.sum_verses_to_meet   != null ) ? item.sum_verses_to_meet   : '',
                        ( item && item.total_verses_to_date != null ) ? item.total_verses_to_date : '',
                    ] : [];

                    return [
                        ( item && item.material ) ? item.material['Material'] :
                            ( item && item.is_christmas ) ? '<i>Christmas</i>' :
                            (meet) ? '<i>Review</i>' : '',
                        ( item && item.material ) ? item.material['Verses']   : '',
                        ...extra_verse_counts,
                    ];
                } ),
                (meet) ? '<b>' + meet['Name'] + '</b><br>' + meet['Label'] : '',
            ].forEach( value => tr.appendChild(
                Object.assign( document.createElement('td'), {
                    innerHTML: value,
                    className: ( Number.isInteger( Number(value) ) ) ? 'right' : '',
                } )
            ) );
        } );
    }

    window.addEventListener( 'DOMContentLoaded', async () => {
        const nodes = [];

        window.document.querySelectorAll(
            'h2 ~ h3:not( h2 + :not( h3, table ) ~ h3 ), h2 ~ table:not(h2 ~ :not( h3, table ) ~ table)',
        ).forEach( node => {
            nodes.push(node);
            node.remove();
        } );

        const cloak_div = document.createElement('div');
        cloak_div.setAttribute( 'v-cloak', '' );
        window.document.querySelector('h2#studyschedule').replaceWith(cloak_div);

        const data = {};
        let header;

        nodes.forEach( node => {
            if ( node.tagName == 'H3' ) {
                header = node.textContent.split( /\s*\bby\b\s*/i );
            }
            else if ( node.tagName == 'TABLE' ) {
                const headers = Array
                    .from( node.querySelectorAll('thead th') )
                    .map( th => th.textContent.trim() );

                const body = Array.from( node.querySelectorAll('tbody tr') ).map( tr => {
                    const cells = tr.querySelectorAll('td');
                    const row   = {};

                    headers.forEach( ( header, index ) =>
                        row[header] = cells[index] ? cells[index].textContent.trim() : null
                    );

                    return row;
                });

                if ( header.length == 1 ) {
                    body.forEach( row => row['Date'] = new Date( row['Date'] ) );
                    data[ header[0] ] = body;
                }
                else if ( header.length > 1 ) {
                    data.blocks ||= {};
                    data.blocks[ header[1] ] ||= [];
                    data.blocks[ header[1] ].push({
                        name: header[0],
                        body: body,
                    });
                }
            }
        } );

        const template         = await template_promise;
        const schedule_div     = document.createElement('div');
        schedule_div.innerHTML = template;

        const select = schedule_div.querySelector('select');
        Object.keys( data.blocks ).forEach( key => select.add( new Option(key) ) );
        const build_display_table_func = event => build_display_table( data, schedule_div, event );
        schedule_div
            .querySelectorAll('fieldset')
            .forEach( select => select.addEventListener( 'change', event => build_display_table_func(event) ) );
        build_display_table_func();

        cloak_div.replaceWith(schedule_div);
    } );
} )();
