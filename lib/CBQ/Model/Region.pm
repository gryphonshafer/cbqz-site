package CBQ::Model::Region;

use exact -class, -conf;
use Data::ModeMerge;
use Mojo::File;
use Omniframe::Class::Time;
use Text::MultiMarkdown 'markdown';
use YAML::XS;

with 'Omniframe::Role::Model';

class_has regional_cms => conf->get('regional_cms');

sub path ($self) {
    return unless ( $self->id );
    my $path = Mojo::File::path( $self->regional_cms->{path_suffix} )->child( $self->data->{acronym} );
    return ( -r $path ) ? $path : undef;
}

sub settings ($self) {
    return unless ( $self->path );

    my $data_merge = Data::ModeMerge->new( config => { parse_prefix => 0, options_key => undef } );
    my $settings   = {};

    $self
        ->path
        ->child( $self->regional_cms->{settings} )
        ->list_tree
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

    return (%$settings) ? $settings : undef;
}

sub all_settings ($self) {
    return {
        map { $_->{key} => $_ }
        grep { $_->{path} }
        map { +{
            key            => lc $_->data->{acronym},
            path           => $_->path,
            maybe settings => $_->settings,
        } }
        $self->every->@*
    };
}

{
    my $time = Omniframe::Class::Time->new;

    sub _node_start_stop ( $node, $days = 1 ) {
        if ( $node->{start} ) {
            $node->{days} //= $days;

            my $start      = $time->parse( $node->{start} );
            $node->{start} = $start->datetime->rfc3339;
            $node->{stop}  = $start->datetime->clone->add( days => $node->{days} - 1 )->rfc3339;
        }
    }

    sub settings_processed ( $self, $settings = undef ) {
        $settings //= $self->settings;

        for my $season ( $settings->{seasons}->@* ) {
            $season->{name} = markdown( $season->{name} ) if ( $season->{name} );
            _node_start_stop( $season, 365 );

            for my $meet ( $season->{meets}->@* ) {
                $meet->{name} = markdown( $meet->{name} ) if ( $meet->{name} );
                $meet->{notes} = markdown( $meet->{notes} ) if ( $meet->{notes} );
                $meet->{host}{name} = markdown( $meet->{host}{name} )
                    if ( $meet->{host} and $meet->{host}{name} );

                _node_start_stop( $meet, 1 );

                if ( $meet->{host} ) {
                    for my $type ( qw( house lunch ) ) {
                        $meet->{host}{$type} = (
                            not $meet->{host}{$type} or
                            lc( substr( $meet->{host}{$type}, 0, 1 ) ) eq 'f'
                        ) ? 0 : 1;
                    }
                }

                # TODO: $meet->{special_material} // $meet->{new_material}
            }
        }

        return $settings;
    }
}

sub all_settings_processed ( $self, $all_settings = undef ) {
    $all_settings //= $self->all_settings;

    $self->settings_processed( $all_settings->{$_}{settings} )
        for ( grep { $all_settings->{$_}{settings} } keys %$all_settings );

    # TODO: handle references between regions

    return $all_settings;
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

=head2 settings

=head2 all_settings

=head2 settings_processed

=head2 all_settings_processed

=head1 WITH ROLE

L<Omniframe::Role::Model>.
