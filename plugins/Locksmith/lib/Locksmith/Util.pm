package Locksmith::Util;

use strict;
use warnings;

use MT;
use Scalar::Util qw( reftype );

my $mt_apply_default_settings;

sub init_app {
    my ($cb, $app) = @_;

    $mt_apply_default_settings = \&MT::Plugin::apply_default_settings;

    require Sub::Install;
    Sub::Install::reinstall_sub({
        code => \&apply_default_settings,
        into => 'MT::Plugin',
        as   => 'apply_default_settings'
    });
}

sub apply_default_settings {
    my ($plugin, $data, $scope_id) = @_;

    # We only want to override the default settings for Locksmith and at the
    # blog level.
    return $mt_apply_default_settings->( @_ )
        unless $plugin->id eq 'locksmith';
    return $mt_apply_default_settings->( @_ )
        if $scope_id eq 'system';

    # Settings can be either a hash or array, depending if they're set at the
    # system or blog level.
    my $settings         = $plugin->registry('settings');
    my $settings_reftype = reftype($settings) || '';
    if ( $settings_reftype eq 'ARRAY' ) {
        my $new_settings;
        for my $opt (@$settings) {
            $new_settings->{ @$opt[0] } = @$opt[1];
        }
        $settings = $new_settings;
    }

    my $sys;
    for my $key (keys %{$settings}) {
        next if exists($data->{$key});
        # don't load system settings unless we need to
        $sys ||= $plugin->get_config_obj('system')->data;
        $data->{$key} = $sys->{$key};
    }
}

1;
