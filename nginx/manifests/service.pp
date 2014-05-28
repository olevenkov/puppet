
class nginx::service {
  service { 'nginx':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => Package['nginx'],
    subscribe  => File['/etc/nginx/nginx.conf'];
  }
}

