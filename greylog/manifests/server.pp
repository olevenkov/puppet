class greylog::server {
  deployable::application { 'server':
    user => 'greylog';
  }

  File { owner => 'greylog', group => 'greylog' }

  file {
    '/home/greylog/apps/server/shared/config/.env':
      ensure => 'present',
      source => [
        "puppet:///modules/greylog/env.$hostname",
        "puppet:///modules/greylog/env.$servergroup",
        'puppet:///modules/greylog/env'
      ];

    '/home/greylog/apps/server/shared/config/graylog2.conf':
      ensure => 'present',
      source => [
        "puppet:///modules/greylog/server/graylog2.conf.$hostname",
        "puppet:///modules/greylog/server/graylog2.conf.$servergroup",
        'puppet:///modules/greylog/server/graylog2.conf'
      ];

    '/home/greylog/apps/server/shared/config/graylog2.drl':
      ensure => 'present',
      source => [
        "puppet:///modules/greylog/server/graylog2.drl.$hostname",
        "puppet:///modules/greylog/server/graylog2.drl.$servergroup",
        'puppet:///modules/greylog/server/graylog2.drl'
      ];
  }
}
