window.addEventListener( 'DOMContentLoaded', () => {
    const table = window.document.querySelector('div.user_list table');
    const box   = window.document.querySelector('div.user_list div.box');
    const rows  = window.document
        .querySelectorAll('div.user_list table tbody tr, div.user_list div.box span');

    const simplified_emails_list = window.document
        .querySelector('div.user_list form input[name="simplified_emails_list"]');

    const set_zone_display = () => {
        if ( simplified_emails_list.checked ) {
            table.classList.add('hidden');
            box.classList.remove('hidden');
        }
        else {
            table.classList.remove('hidden');
            box.classList.add('hidden');
        }
    };

    const role_checkboxes = [];

    window.document.querySelectorAll(
        'div.user_list form input[type="checkbox"]:not([name="simplified_emails_list"])'
    ).forEach( input => {
        role_checkboxes.push(input);
        input.checked = false;
        input.addEventListener( 'change', () => {
            const selected_roles = role_checkboxes
                .filter( checkbox => checkbox.checked )
                .map( checkbox => checkbox.name );

            let something = false;
            rows.forEach( row => {
                const roles = row.getAttribute('data-roles');
                if ( selected_roles.length == 0 ) {
                    row.classList.remove('hidden');
                    something = true;
                }
                else {
                    row.classList.add('hidden');
                    if ( roles && roles.split('|').some( role => selected_roles.includes(role) ) ) {
                        row.classList.remove('hidden');
                        something = true;
                    }
                }
            } );

            if ( ! something ) {
                table.classList.add('hidden');
                box.classList.add('hidden');
            }
            else {
                set_zone_display();
            }
        } );
    } );

    simplified_emails_list.checked = false;
    simplified_emails_list.addEventListener( 'change', set_zone_display );
} );
