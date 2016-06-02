package Locksmith::Util;

use MT;
use Data::Dumper;
$Data::Dumper::Maxdepth = 99;

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

    my $sys;
    for my $key (keys %{$plugin->registry('settings')}) {
        next if exists($data->{$key});
        # don't load system settings unless we need to
        $sys ||= $plugin->get_config_obj('system')->data;
        $data->{$key} = $sys->{$key};
    }
}

1;
