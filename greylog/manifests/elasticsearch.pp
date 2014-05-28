class greylog::elasticsearch {
  include greylog::elasticsearch::too_many_files_fix

  deployable::application { 'elasticsearch':
    user => 'greylog';
  }

  File { owner => 'greylog', group => 'greylog' }

  file {
    '/data/elasticsearch/':
      ensure => 'directory';

    '/home/greylog/apps/elasticsearch/shared/config/elasticsearch.yml':
      ensure => 'present',
      source => [
        "puppet:///modules/greylog/elasticsearch/elasticsearch.yml.${hostname}",
        "puppet:///modules/greylog/elasticsearch/elasticsearch.yml.${servergroup}",
        'puppet:///modules/greylog/elasticsearch/elasticsearch.yml',
      ];

    '/home/greylog/apps/elasticsearch/shared/config/logging.yml':
      ensure => 'present',
      source => [
        "puppet:///modules/greylog/elasticsearch/logging.yml.${hostname}",
        "puppet:///modules/greylog/elasticsearch/logging.yml.${servergroup}",
        'puppet:///modules/greylog/elasticsearch/logging.yml',
      ];

    '/home/greylog/apps/elasticsearch/shared/config/.env':
      ensure => 'present',
      owner  => 'greylog',
      group  => 'greylog',
      source => [
        "puppet:///modules/greylog/env.$hostname",
        "puppet:///modules/greylog/env.$servergroup",
        'puppet:///modules/greylog/env'
      ];
  }
}
