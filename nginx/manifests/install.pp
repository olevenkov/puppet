
class nginx::install {
  File {
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    require => Package['nginx']
  }

  file {
    '/etc/nginx/nginx.conf':
      ensure => present,
      source => [
        "puppet:///modules/nginx/nginx.conf.${servergroup}",
        'puppet:///modules/nginx/nginx.conf'
      ];

    '/etc/nginx/mime.types':
      ensure => present,
      source => 'puppet:///modules/nginx/mime.types';

    '/etc/nginx/conf.d/default.conf':
      ensure => absent;

    '/etc/nginx/conf.d/example_ssl.conf':
      ensure => absent;
  }

  package { 'nginx':
    ensure  => latest,
    require => Yumrepo['nginx'];
  }

  yumrepo { 'nginx':
    descr    => 'Official NGINX Repository',
    baseurl  => "http://nginx.org/packages/centos/$lsbmajdistrelease/\$basearch/",
    enabled  => '1',
    gpgcheck => '0'
  }
}

