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
                    data.reg            ||= {};
                    data.reg.orgs       ||= [];
                    data.reg.user       ||= {};
                    data.reg.user.roles ||= [];

                    if ( data.reg.user.attend  == undefined ) data.reg.user.attend  = 0;
                    if ( data.reg.user.drive   == undefined ) data.reg.user.drive   = 0;
                    if ( data.reg.user.housing == undefined ) data.reg.user.housing = 0;
                    if ( data.reg.user.lunch   == undefined ) data.reg.user.lunch   = 1;

                    data.changed = false;

                    return data;
                },

                computed: {
                    cant_register_teams() {
                        return (
                            this.reg.orgs.length &&
                            this.reg.user.roles.includes('Coach')
                        ) ? false : true;
                    },

                    can_edit() {
                        return ! this.meet.registration_closed;
                    },
                },

                methods: {
                    add_team(org) {
                        var team = [];
                        org.teams.push(team);
                        this.add_quizzer(team);
                    },

                    add_quizzer(team) {
                        var quizzer = {
                            bible  : 'NIV',
                            rookie : false,
                            attend : true,
                            housing: false,
                            lunch  : true,
                            verses : 0,
                        };
                        team.push(quizzer);
                    },

                    reorder( direction, org_index, team_index, person_index ) {
                        const teams   = this.reg.orgs[org_index].teams;
                        const element = teams[team_index].splice( person_index, 1 )[0];

                        if ( direction == -1 ) {
                            if ( person_index != 0 ) {
                                teams[team_index].splice( person_index - 1, 0, element );
                            }
                            else {
                                var target = team_index - 1;
                                if ( target < 0 ) target = teams.length - 1;
                                teams[target].push(element);
                            }
                        }
                        else if ( direction == 1 ) {
                            if ( person_index != teams[team_index].length ) {
                                teams[team_index].splice( person_index + 1, 0, element );
                            }
                            else {
                                var target = team_index + 1;
                                if ( target > teams.length - 1 ) target = 0;
                                teams[target].unshift(element);
                            }
                        }

                        if ( teams[team_index].length == 0 ) teams.splice( team_index, 1 );
                    },

                    delete_quizzer( org_index, team_index, person_index ) {
                        const teams = this.reg.orgs[org_index].teams;
                        teams[team_index].splice( person_index, 1 );
                        if ( teams[team_index].length == 0 ) teams.splice( team_index, 1 );
                    },

                    add_nonquizzer(org_index) {
                        this.reg.orgs[org_index].nonquizzers.push({
                            attend :  true,
                            housing: false,
                            lunch  :  true,
                        });
                    },

                    delete_nonquizzer( org_index, person_index ) {
                        this.reg.orgs[org_index].nonquizzers.splice( person_index, 1 );
                    },

                    save_registration() {
                        this.changed = false;

                        const generic_error = {
                            message: 'Meet registration data not saved.',
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
                                body: JSON.stringify( this.reg ),
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
                    },
                },

                watch: {
                    reg: {
                        handler() {
                            this.changed = true;
                        },
                        deep: true,
                    },
                },
            })
            .mount('#register')
    );
