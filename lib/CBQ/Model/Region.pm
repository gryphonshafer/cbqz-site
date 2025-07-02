package CBQ::Model::Region;

use exact -class, -conf;
use Bible::Reference;
use Data::ModeMerge;
use Mojo::File;
use Omniframe::Class::Time;
use Text::MultiMarkdown 'markdown';
use YAML::XS;

with 'Omniframe::Role::Model';

class_has active       => 1;
class_has regional_cms => conf->get('regional_cms');
class_has docs_dir     => conf->get( qw( docs dir ) );

my $time = Omniframe::Class::Time->new;
my $bref = Bible::Reference->new( simplify => 1 );

sub path ($self) {
    return unless ( $self->id );
    my $path = Mojo::File::path( $self->regional_cms->{path_suffix} )->child( lc $self->data->{acronym} );
    return ( -r $path ) ? $path : undef;
}

sub settings ($self) {
    return unless ( $self->path );

    my $settings   = {};
    my $data_merge = Data::ModeMerge->new( config => {
        parse_prefix => 0,
        default_mode => 'ADD',
    } );

    $self
        ->path
        ->child( $self->regional_cms->{settings} )
        ->list_tree
        ->grep( sub {
            ( lc( $_->extname ) eq 'yaml' or lc( $_->extname ) eq 'yml' )
            and substr( $_->basename, 0, 1 ) ne '_'
        } )
        ->each( sub {
            my $data = {};
            try {
                my $result = $data_merge->merge( $settings, YAML::XS::Load( $_->slurp('UTF-8') ) );
                die $result->{error} if ( $result->{error} );
                $settings = $result->{result};
            }
            catch ($e) {
                $self->error( 'Failed YAML parse/integrate: ' . $_->to_string . ' -- ' . deat($e) );
            }
        } );

    return ( $settings and %$settings ) ? $settings : {};
}

sub all_settings ($self) {
    return {
        map { $_->{key} => $_ }
        grep {
            -d $_->{path} and
            -f $_->{path}->child( $self->docs_dir . '/index.md' )
        }
        map { +{
            id             => $_->id,
            key            => lc $_->data->{acronym},
            name           => $_->data->{name},
            path           => $_->path,
            maybe settings => $_->settings,
        } }
        $self->every->@*
    };
}

sub _node_start_stop ( $node, $days = 1 ) {
    my $start;

    if ( $node->{start} ) {
        $node->{days} //= $days;

        $start   = $time->parse( $node->{start} )->datetime;
        my $stop = $start->clone->add( days => $node->{days} - 1, hours => 4 );

        $node->{start_time} = $start->epoch;
        $node->{stop_time}  = $stop ->epoch;

        $node->{start} = $start->rfc3339;
        $node->{stop}  = $stop ->rfc3339;
    }

    return $start;
}

sub _process ( $self, $settings = undef ) {
    $settings //= $self->settings;

    my $material = '';
    for my $season ( $settings->{seasons}->@* ) {
        _node_start_stop( $season, 365 );

        $season->{name} = markdown( $season->{name} ) if ( $season->{name} );

        for my $meet ( $season->{meets}->@* ) {
            my $meet_start = _node_start_stop( $meet, 1 );

            for my $type ( qw( deadline reminder ) ) {
                next if ( defined $meet->{$type} and not $meet->{$type} );

                $meet->{ $type . '_days' } //=
                    $meet->{$type} // $season->{$type} // conf->get( 'registration', $type );

                my $type_datetime = $meet_start->subtract( days => $meet->{ $type . '_days' } )->set(
                    hour   => 23,
                    minute => 59,
                    second => 59,
                );

                $meet->{ $type . '_time' } = $type_datetime->epoch;
                $meet->{ $type           } = $type_datetime->rfc3339;
            }

            $meet->{name}       = markdown( $meet->{name}  ) if ( $meet->{name}  );
            $meet->{notes}      = markdown( $meet->{notes} ) if ( $meet->{notes} );
            $meet->{host}{name} = markdown( $meet->{host}{name} )
                if ( $meet->{host} and $meet->{host}{name} );

            if ( $meet->{host} ) {
                for my $type ( qw( housing lunch ) ) {
                    $meet->{host}{$type} = (
                        not $meet->{host}{$type} or
                        lc( substr( $meet->{host}{$type}, 0, 1 ) ) eq 'f'
                    ) ? 0 : 1;
                }
            }

            if ( $meet->{material} ) {
                delete $meet->{$_} for ( qw( old_material new_material special_material ) );
                $meet->{old_material} = $bref->clear->in($material)->refs if ($material);
                $material = $meet->{material} = $bref->clear->in( $meet->{material} )->text;
            }
            elsif ( $meet->{special_material} or $meet->{new_material} ) {
                delete $meet->{old_material};
                $meet->{old_material} = $bref->clear->in($material)->refs if ($material);

                my $this_material = $bref->clear->in(
                    $meet->{special_material} // $meet->{new_material}
                )->refs;

                $meet->{
                    ( $meet->{special_material} ) ? 'special_material' : 'new_material'
                } = $this_material;

                $meet->{material} =
                    ( ( $meet->{old_material} ) ? $meet->{old_material} . ' (1) ' : '' ) .
                    $this_material .
                    ( ( $meet->{old_material} ) ? ' (1)' : '' );

                $material = $meet->{material} unless ( $meet->{special_material} );
            }
            else {
                $meet->{material} = $meet->{old_material} = $bref->clear->in($material)->refs;
            }
        }
    }

    return;
}

sub settings_processed ( $self, $settings = undef ) {
    $settings //= $self->settings;
    $self->_process($settings);
    return $settings;
}

sub all_settings_processed ( $self, $all_settings = undef ) {
    $all_settings //= $self->all_settings;

    for my $key ( keys %$all_settings ) {
        next unless (
            $all_settings->{$key}{settings} and
            $all_settings->{$key}{settings}{seasons}
        );

        for my $season ( $all_settings->{$key}{settings}{seasons}->@* ) {
            next unless ( $season->{meets} );

            for my $remote_meet ( grep { $_->{region} } $season->{meets}->@* ) {
                my ($foreign_season) =
                    grep { $_->{name} eq $season->{name} }
                    $all_settings->{ lc $remote_meet->{region} }{settings}{seasons}->@*;
                next unless ( $foreign_season and $foreign_season->{meets} );

                my ($foreign_meet) = grep { $_->{name} eq $remote_meet->{name} } $foreign_season->{meets}->@*;
                next unless ($foreign_meet);

                $remote_meet->{$_} //= $foreign_meet->{$_} for ( keys %$foreign_meet );
            }
        }
    }

    $self->_process($_) for (
        map { $all_settings->{$_}{settings} }
        grep { $all_settings->{$_}{settings} }
        keys %$all_settings
    );

    return $all_settings;
}

sub current_season ( $self, $seasons_or_region ) {
    my $seasons = ( ref $seasons_or_region )
        ? $seasons_or_region
        : $self->all_settings_processed->{ lc $seasons_or_region }{settings}{seasons};

    my $now = time;
    my ($current_season) =
        sort { $b->{stop_time} <=> $a->{stop_time} }
        grep { $_->{start_time} <= $now and $_->{stop_time} >= $now }
        $seasons->@*;

    ($current_season) = sort { $b->{start_time} <=> $a->{start_time} } $seasons->@* unless ($current_season);

    my $seen_current_next_meet;
    for my $meet ( $current_season->{meets}->@* ) {
        delete $meet->{$_} for ( qw( is_current_next_meet registration_closed ) );

        if ( $meet->{stop_time} > $now and not $seen_current_next_meet ) {
            $seen_current_next_meet       = 1;
            $meet->{is_current_next_meet} = 1;
            $meet->{registration_closed}  = 1
                if ( not $meet->{deadline_time} or $meet->{deadline_time} < $now );
        }
    }

    return $current_season;
}

sub all_current_next_meets ($self) {
    my $settings = $self->all_settings_processed;

    return [
        grep { defined }
        map {
            my $key = $_;
            my ($current_next_meet) =
                grep { $_->{is_current_next_meet} }
                $self->current_season( $settings->{$key}{settings}{seasons} )->{meets}->@*;

            $current_next_meet->{region} = { map { $_ => $settings->{$key}{$_} } qw( id key name ) }
                if ($current_next_meet);

            $current_next_meet;
        }
        keys %$settings
    ];
}

sub reminder_meets ($self) {
    my $now = time;
    return [ grep {
        not $_->{registration_closed}
        and $_->{deadline}
        and abs( $_->{reminder_time} - $now ) < 60 * 60 * 24
    } $self->all_current_next_meets->@* ];
}

1;

=head1 NAME

CBQ::Model::Region

=head1 SYNOPSIS

    use CBQ::Model::Region;

=head1 DESCRIPTION

This class is the model for region objects and associated scalar and list methods.

=head1 METHODS

=head2 path

Returns a L<Mojo::File> path for a loaded region object (and undef for unloaded)
that's the files root directory for the region. It's built from a combination of
the C<regional_cms> C<path_suffix> configuration and the region's C<acronym>.
See L</"CONFIGURATION"> below.

=head2 settings

This method will return a single settings nested data structure built by merging
however many configuration files are found under the C<regional_cms> C<settings>
configuration. See L</"CONFIGURATION"> below.

Note that no changes to the underlying data happen; just merging and returning
the data. See L</"settings_processed"> below.

=head3 Settings YAML

The following is an example of a combined settings YAML. Any part of this data
can be separated into separate files to be merged under a C<settings> call.

    ---
    redirects:
        /url/path: /some/other/destination
    seasons:
      - name: Corinthians
        start: Aug 1, 2025
        days: 280 # defaults to 365
        deadline: 14
        reminder: 7
        meets:
          - name: Scramble
            start: Sep 13 2025 8 AM PDT
            special_material: 1 Cor 1-4
            deadline: 0
            reminder: 7
            host:
                name: Lighthouse Christian Center
                url: https://lighthousehome.org
                address: 3409 23rd St SW, Puyallup WA 98373
                lunch: true # defaults to false
          - name: Meet 1
            start: Oct 11 2025 8 AM PDT
            days: 2 # defaults to 1
            new_material: 1 Cor 1-6
            host:
                name: Juniper Community Church
                url: https://junipercc.com
                address: 976 S Adams Dr, Madras OR 97741
                housing: true # defaults to false
                lunch: true # defaults to false
            notes: |
                - Arrive Friday for dinner.
                - Quizzing on Saturday.
          - name: Meet 2
            region: INW # inherit "Meet 2" from the INW region's settings

=head2 all_settings

This method returns a data structure that includes the C<settings> of all
regions. The returned value is a hashref, with keys of C<key> per each region
(where the value is the lower-case acronym of the region), and values of a
hashref with keys of C<key> (same as the previous C<key>), C<path> (same as from
the C<path> method of this object), and possibly C<settings> if any settings
exist.

=head2 settings_processed

This method internally calls C<settings> and then post-processes the data. It
will set default C<days> values if any aren't set. It'll also process C<name>
and C<notes> fields as Markdown. It will convert "true" or "false" values for
C<housing> and C<lunch> into 1 or 0 respectively. And where C<start> and C<days>
values exist, it'll convert these into C<start> and C<stop> fields with
RFC 3339 date/time values. Lastly, it'll interpret the material range from
C<new_material>, combining it with any previous material, and output a combined
material description (sans translations). If C<special_material> exists instead,
it will be assumed to be material for the single meet and won't be added to the
cumulative season material.

=head2 all_settings_processed

This method is like calling C<all_settings> that for each region calls
C<settings_processed>, but then in addition will process inherited meets across
regions.

=head2 current_season

Requires either an arrayref of seasons or the key/acronym for a region. Will
return the current season with the current or next meet marked as such.

=head2 all_current_next_meets

Returns an arrayref of hashrefs, each representing a meet that is the current
next meet for any region, season, and meet set.

=head2 reminder_meets

Returns an arrayref of hashrefs like C<all_current_next_meets> but filtered to
only include meets that should have reminders sent for them on the current day.

=head1 CONFIGURATION

The following is the expected initial configuration, which can be changed in the
application's configuration file. See L<Config::App>.

    regional_cms:
        path_suffix: ../regions
        settings   : config

=head1 WITH ROLE

L<Omniframe::Role::Model>.
