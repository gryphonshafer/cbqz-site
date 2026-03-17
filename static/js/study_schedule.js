const template_url     = new URL( document.currentScript.src );
template_url.pathname  = '/html/study_schedule.html';
const template_promise = fetch(template_url).then( response => response.text() );

function date_display(date) {
    return date.toLocaleDateString( 'en-US', {
        weekday: 'short',
        month  : 'short',
        day    : 'numeric',
    } );
}

function build_display_table( data, select, div ) {
    const table = div.querySelector('table');
    const thead = table.querySelector('thead');
    const tbody = table.querySelector('tbody');

    [ thead, tbody ].forEach( node => {
        while ( node.firstChild ) {
            node.removeChild( node.firstChild );
        }
    } );

    const tr = thead.insertRow();
    [
        'Week Start',
        'Week End',
        'Material',
        'Verses',
        'Sum',
        'Total',
        'Meet / Label',
    ].forEach( label => tr.appendChild(
        Object.assign( document.createElement('th'), { textContent: label } )
    ) );

    const date_cursor = new Date( data['Meet Dates'].at(-1)['Date'] );
    date_cursor.setDate(
        date_cursor.getDate() -
        (
            data['Meet Dates'].length +
            Math.max( ...Object.values( data.blocks[ select.value ] ).map( array => array.length ) ) +
            0
        ) * 7 + 1
    );

    let material_i           = 0;
    let sum_verses_to_meet   = 0;
    let total_verses_to_date = 0;

    while ( date_cursor <= data['Meet Dates'].at(-1)['Date'] ) {
        const date_week_end = new Date(date_cursor);
        date_week_end.setDate( date_week_end.getDate() + 6 );

        const meet = data['Meet Dates']
            .find( meet => meet['Date'] >= date_cursor && meet['Date'] <= date_week_end );

        const material    = data.blocks[ select.value ]['Full Material'][material_i];
        const progression = ( meet && meet['Name'] != 'Scramble' || ! material );

        if (progression) sum_verses_to_meet = 0;
        if ( ! progression && material ) {
            sum_verses_to_meet   += Number( material['Verses'] );
            total_verses_to_date += Number( material['Verses'] );
        }

        const tr = tbody.insertRow();
        [
            date_display( date_cursor   ),
            date_display( date_week_end ),

            (progression) ? '<i>Review</i>' : material['Material'],
            (progression) ? ''              : material['Verses'],
            (progression) ? ''              : sum_verses_to_meet,
            (progression) ? ''              : total_verses_to_date,

            (meet) ? '<b>' + meet['Name'] + '</b><br>' + meet['Label'] : '',
        ].forEach( value => tr.appendChild(
            Object.assign( document.createElement('td'), {
                innerHTML: value,
                className: ( Number.isInteger( Number(value) ) ) ? 'right' : '',
            } )
        ) );

        if ( ! progression ) material_i++;
        date_cursor.setDate( date_cursor.getDate() + 7 );
    }
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
                data.blocks[ header[1] ] ||= {};
                data.blocks[ header[1] ][ header[0] ] = body;
            }
        }
    } );

    const template         = await template_promise;
    const schedule_div     = document.createElement('div');
    schedule_div.innerHTML = template;

    const select = schedule_div.querySelector('select');
    Object.keys( data.blocks ).forEach( key => select.add( new Option(key) ) );

    const build_display_table_func = () => build_display_table( data, select, schedule_div );
    select.addEventListener( 'change', build_display_table_func );
    build_display_table_func();

    cloak_div.replaceWith(schedule_div);
} );
