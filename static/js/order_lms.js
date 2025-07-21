const url = new URL( window.location.href );
fetch( new URL( url.pathname + '.json', url ) )
    .then(
        reply => reply.json().then( data => ( {
            data: data,
            csrf: reply.headers.get('X-CSRF-Token'),
        } ) )
    )
    .then( ( { data, csrf } ) =>
        Vue
            .createApp({
                data() {
                    for ( let component of data.components ) {
                        component.count = component.count ?? component.default;
                        component.cost  = component.count * component.cost_per;
                    }

                    data.arrange_pick     = false;
                    data.rookie_org       = false;
                    data.total_cost       = 0;
                    data.person_name      = '';
                    data.person_email     = '';
                    data.person_phone     = '';
                    data.person_address   = '';
                    data.shipping_address = '';
                    data.org_name         = '';
                    data.org_acronym      = '';
                    data.org_address      = '';
                    data.region_name      = '';

                    return data;
                },

                computed: {
                    sum_cost() {
                        let sum_cost = 0;
                        for ( let component of this.components ) {
                            component.cost = component.cost_per * (
                                ( this.rookie_org )
                                    ? component.count - component.default
                                    : component.count
                            );

                            sum_cost += component.cost;
                        }
                        this.total_cost = sum_cost + ( this.arrange_pick ? 0 : this.shipping );
                        return this.total_cost;
                    },
                },

                methods: {
                    currency(value) {
                        if ( typeof value !== 'number' ) return value;
                        return new Intl.NumberFormat(
                            'en-US',
                            {
                                style   : 'currency',
                                currency: 'USD',
                            },
                        ).format(value);
                    },

                    min_units(component) {
                        return ( this.rookie_org ) ? component.default : 0;
                    },

                    submit_order() {
                        const form_data = JSON.parse( JSON.stringify( Vue.toRaw( this.$data ) ) );
                        let incomplete_form = false;

                        if (
                            form_data.person_name.length      == 0 ||
                            form_data.person_email.length     == 0 ||
                            form_data.person_phone.length     == 0 ||
                            form_data.person_address.length   == 0 ||
                            form_data.shipping_address.length == 0
                        ) incomplete_form = true;

                        if ( this.rookie_org ) {
                            if (
                                form_data.org_name.length    == 0 ||
                                form_data.org_acronym.length == 0 ||
                                form_data.org_address.length == 0 ||
                                form_data.region_name.length == 0
                            ) incomplete_form = true;
                        }

                        if (incomplete_form) {
                            omniframe.memo({
                                message: 'Form incomplete. Please fill out every visible field in the form.',
                                class  : 'error',
                            });
                        }
                        else {
                            const generic_error = {
                                message: 'Lesser Magistrate (LM) order not executed.',
                                class  : 'error',
                            };

                            fetch(
                                url,
                                {
                                    method: 'POST',
                                    headers: {
                                        'Content-Type': 'application/json',
                                        'X-CSRF-Token': csrf,
                                    },
                                    body: JSON.stringify(form_data),
                                },
                            )
                                .then( result => {
                                    if ( ! result.ok ) throw generic_error;
                                    return result.json();
                                } )
                                .then( memo => {
                                    throw memo || generic_error;
                                } )
                                .catch( memo => omniframe.memo(memo) );
                        }
                    },
                },

                watch: {
                    rookie_org() {
                        for ( let component of this.components ) {
                            const this_min_units = this.min_units(component);
                            if ( this_min_units > component.count ) component.count = this_min_units;
                        }
                    },
                },
            })
            .mount('#order_lms')
    );
