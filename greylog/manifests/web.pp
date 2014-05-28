# Configures the https://github.com/nature/graylog2-web-interface application.
#
# Maintainer: Chris Lowder <c.lowder@nature.com>
#
class greylog::web {
  include rvm_to_rbenv

  deployable::application { 'web':
    user => 'greylog';
  }

  cron {
    'greylog-alarms':
      ensure => 'absent';
    'greylog-subscriptions':
      ensure => 'absent';

    'alarms':
      command => '/usr/bin/flock -n /home/greylog/apps/web/shared/pids/alarms.lock -c "/home/greylog/apps/web/shared/script/alarms"',
      user    => 'greylog',
      minute  => '*/15';

    'subscriptions':
      command => '/usr/bin/flock -n /home/greylog/apps/web/shared/pids/subscriptions.lock -c "/home/greylog/apps/web/shared/script/subscriptions"',
      user    => 'greylog',
      minute  => '*/15';
  }


  File{ owner => 'greylog', group => 'greylog' }

  file {
    '/home/greylog/apps/web/shared/script':
      ensure => 'directory',
      owner  => 'greylog',
      group  => 'greylog';

    '/home/greylog/apps/web/shared/config/email.yml':
      ensure  => 'present',
      source  => [
        "puppet:///modules/greylog/web/email.yml.${hostname}",
        "puppet:///modules/greylog/web/email.yml.${servergroup}",
        'puppet:///modules/greylog/web/email.yml'
      ];

    '/home/greylog/apps/web/shared/config/general.yml':
      ensure  => 'present',
      source  => [
        "puppet:///modules/greylog/web/general.yml.${hostname}",
        "puppet:///modules/greylog/web/general.yml.${servergroup}",
        'puppet:///modules/greylog/web/general.yml'
      ];

    '/home/greylog/apps/web/shared/config/indexer.yml':
      ensure  => 'present',
      source  => [
        "puppet:///modules/greylog/web/indexer.yml.${hostname}",
        "puppet:///modules/greylog/web/indexer.yml.${servergroup}",
        'puppet:///modules/greylog/web/indexer.yml'
      ];

    '/home/greylog/apps/web/shared/config/ldap.yml':
      ensure  => 'present',
      source  => [
        "puppet:///modules/greylog/web/ldap.yml.${hostname}",
        "puppet:///modules/greylog/web/ldap.yml.${servergroup}",
        'puppet:///modules/greylog/web/ldap.yml'
      ];

    '/home/greylog/apps/web/shared/config/mongoid.yml':
      ensure  => 'present',
      source  => [
        "puppet:///modules/greylog/web/mongoid.yml.${hostname}",
        "puppet:///modules/greylog/web/mongoid.yml.${servergroup}",
        'puppet:///modules/greylog/web/mongoid.yml'
      ];

    '/home/greylog/apps/web/shared/script/subscriptions':
      ensure => present,
      source => 'puppet:///modules/greylog/web/script/subscriptions',
      mode   => '744';

    '/home/greylog/apps/web/shared/script/alarms':
      ensure => present,
      source => 'puppet:///modules/greylog/web/script/alarms',
      mode   => '744';
  }
}
