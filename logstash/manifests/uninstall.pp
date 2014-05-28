class logstash::uninstall {
  service {
    'logstash':
      ensure     => 'stopped',
      provider   => 'runit',
      enable     => false;
  }

  file {
    '/opt/logstash':
      ensure  => absent,
      recurse => true,
      require => Service['logstash'];
  }
}
