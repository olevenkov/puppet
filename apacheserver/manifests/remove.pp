class apacheserver::remove {
  package { 'httpd': ensure => absent }

  file {
    '/usr/local/scripts/rotatehttpd.sh':
      ensure => absent;
    '/etc/httpd':
      ensure => absent,
      force  => true;
  }

  cron { 'rotatehttpd':
    ensure  => absent,
    command => '/usr/local/scripts/rotatehttpd.sh',
    user    => 'root',
  }
}
