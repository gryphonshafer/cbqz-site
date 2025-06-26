const url = new URL( window.location.href );
fetch( new URL( url.pathname + '.json', url ) )
    .then( reply => reply.json() )
    .then( json_data =>
        Vue
            .createApp({
                data() {
                    return json_data;
                },

                computed: {
                    can_register_teams() {
                        return (
                            this.reg.orgs.length &&
                            (
                                this.user.info.roles.includes('Coach') ||
                                this.reg.user.roles.includes('Coach')
                            )
                        ) ? true : false;
                    },
                },

                methods : {
                    add_team : function (org) {
                        var team = [];
                        org.teams.push(team);
                        this.add_quizzer(team);
                        // this.nav_content_align();
                    },

                    add_quizzer : function (team) {
                        var quizzer = {
                            bible : 'NIV',
                            rookie: false,
                            attend: true,
                            house : false,
                            lunch : true,
                        };
                        team.push(quizzer);
                        // this.add_watch(quizzer);
                        // this.nav_content_align();
                    },

                    reorder : function ( direction, org_index, team_index, person_index ) {
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

                    delete_quizzer : function ( org_index, team_index, person_index ) {
                        const teams = this.reg.orgs[org_index].teams;
                        teams[team_index].splice( person_index, 1 );
                        if ( teams[team_index].length == 0 ) teams.splice( team_index, 1 );
                        // this.nav_content_align();
                    },
                },

                // TODO
                    // delete_nonquizzer : function (person_index) {
                    //     this.nonquizzers.splice( person_index, 1 );
                    //     this.nav_content_align();
                    // },

                    // save_registration : function () {
                    //     var register = document.getElementById("register_save");
                    //     register.elements[0].value = JSON.stringify(register_data);
                    //     register.submit();
                    // }

                //     add_nonquizzer : function (team) {
                //         var nonquizzer = { house : true, lunch : true };
                //         this.nonquizzers.push(nonquizzer);
                //         this.nav_content_align();
                //     },

                //     add_watch : function (record) {
                //         this.$watch(
                //             function () {
                //                 return record.attend;
                //             },
                //             ( function () {
                //                 var _record = record;

                //                 return function (attend) {
                //                     if ( attend == null ) return;
                //                     _record.house  = attend;
                //                     _record.lunch  = attend;
                //                     _record.driver = null;
                //                 }
                //             } )()
                //         );
                //     },

                //     nav_content_align : function () {
                //         this.$nextTick( function () {
                //             nav_content_align.align();
                //         } );
                //     },

                // watch: {
                //     $data: {
                //         handler: function () {
                //             if ( ! this.changed ) this.nav_content_align();
                //             this.changed = 1;
                //         },
                //         deep: true
                //     }
                // },

                // mounted : function () {
                //     for ( var t = 0; t < this.teams.length; t++ ) {
                //         for ( var q = 0; q < this.teams[t].length; q++ ) {
                //             this.add_watch( this.teams[t][q] );
                //         }
                //     }

                //     this.nav_content_align();
                // }
            })
            .mount('#register')
    );
