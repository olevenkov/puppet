class logstash::install {
  $logstash_config = '/opt/logstash/logshipper.conf'

  group { 'logstash':
    ensure => absent,
  }

  user { 'logstash':
    ensure     => absent,
    shell      => '/bin/bash',
    gid        => 'logstash',
    managehome => true,
    require    => Group['logstash'],
  }

  file {
    '/opt/':
      ensure => directory,
      owner  => 'root',
      group  => 'root';

    '/opt/logstash':
      ensure => directory,
      owner  => 'root',
      group  => 'root';

    '/opt/logstash/logstash-monolithic.jar':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => 'puppet:///modules/logstash/logstash-1.0.17-monolithic.jar';

    $logstash_config:
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => [
        "puppet:///modules/logstash/logshipper.conf.$::hostname",
        "puppet:///modules/logstash/logshipper.conf.$::servergroup",
        'puppet:///modules/logstash/logshipper.conf'
      ];
  }

  # Setup the system level service.
  $service_log_path        = '/opt/logstash/log'
  $service_path            = '/etc/sv/logstash'
  $service_script          = "${ service_path }/run"
  $service_log_script_path = "${ service_path }/log"
  $service_log_script      = "${ service_path }/log/run"

  file {
    [$service_path, $service_log_path, $service_log_script_path]:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0775';

    $service_script:
      ensure  => file,
      source  => 'puppet:///modules/logstash/run',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File[$service_path],
      notify  => Service['logstash'];

    $service_log_script:
      ensure  => file,
      source  => 'puppet:///modules/logstash/log',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => [
        File[$service_log_path],
        File[$service_log_script_path]
      ],
      notify  => Service['logstash'];
  }

  service {
    'logstash':
      ensure     => 'running',
      provider   => 'runit',
      enable     => true,
      hasrestart => true,
      hasstatus  => true,
      subscribe  => [
        File[$service_script],
        File[$logstash_config]
      ];
  }
}
