#
# This definition creates an NGINX virtual host
#
# ensure               - Enables or disables the specified vhost (present|absent)
# listen               - Default IP Address for NGINX to listen with this vHost on. Defaults to all interfaces (*)
# listen_port          - Default IP Port for NGINX to listen with this vHost on. Defaults to TCP 80
# ipv6_enable          - BOOLEAN, enable IPv6 support? Defaults to FALSE.
# ipv6_listen          - Default IPv6 Address for NGINX to listen with this vHost on. Defaults to all interfaces (::)
# ipv6_listen_port     - Default IPv6 Port for NGINX to listen with this vHost on. Defaults to TCP 80
# index_files          - Default index files for NGINX to read when traversing a directory
# ssl_enable           - BOOLEAN, use SSL? Defaults to FALSE.  You MUST supply ssl_cert and ssl_cert_key if you enable this.
# ssl_cert             - Pre-generated SSL Certificate file to reference for SSL Support. This is not generated by this module.
# ssl_key              - Pre-generated SSL Key file to reference for SSL Support. This is not generated by this module.
# app_servers          - Application server(s) for the root location proxy to (accepts an array of nginx 'server' directives).
#                        These application servers will be loadbalanced using the 'upstream' directive in nginx.
# proxy_buffering_off  - BOOLEAN, for Comet/long-polling applications it is important to set proxy_buffering to off, otherwise
#                        the asynchronous response is buffered and the Comet does not work.
# www_root             - Specifies the location on disk for static files to be read from.
# server_names         - An array of server names to match this vhost entry against.  Defaults to [$name].
#                        (See http://wiki.nginx.org/HttpCoreModule#server_name for details.)
#
# Examples
#
#  nginx::vhost {
#    'rails.nature.com':
#      ensure      => present,
#      listen_port => '4567',
#      www_root    => '/home/rails/apps/current/public',
#      app_servers => [
#        '127.0.0.1:5000',
#        '127.0.0.1:5001',
#        '127.0.0.1:5002',
#        '127.0.0.1:5003'
#      ];
#  }
#
# This will setup a loadbalanced proxy to a ruby/rails app running 4 instances of
# thin/mongrel etc. and listen to external connections on port 4567.  It will also
# serve all static assests by default (through nginx) rather than going through the
# app server.
#
#  nginx::vhost {
#    'static.nature.com':
#      ensure      => present,
#      www_root    => '/var/www/static-site';
#  }
#
# This will setup/serve a static site listening on port 80. Simples.
#
define nginx::vhost(
  $ensure              = 'present',
  $listen              = '*',
  $listen_port         = '80',
  $ipv6_enable         = false,
  $ipv6_listen         = '::',
  $ipv6_listen_port    = '80',
  $index_files         = ['index.html', 'index.htm'],
  $ssl_enable          = false,
  $ssl_cert            = false,
  $ssl_cert_key        = false,
  $app_servers         = [],
  $proxy_buffering_off = false,
  $www_root            = '',
  $server_names        = [$name],
  $http_basic_auth     = false,
  $htpasswd_file       = ''
) {
  file { "/etc/nginx/conf.d/${name}.conf":
    ensure  => $ensure,
    owner   => root,
    group   => root,
    mode    => '0640',
    content => template('nginx/vhost.erb'),
    require => Package['nginx'],
    notify  => Service['nginx']
  }

  if $http_basic_auth {
    file { "/etc/nginx/conf.d/${name}.htpasswd":
      ensure  => 'present',
      owner   => root,
      group   => root,
      mode    => '0644',
      source  => $htpasswd_file,
      require => File["/etc/nginx/conf.d/${name}.conf"],
      notify  => Service['nginx'];
    }
  } else {
    file { "/etc/nginx/conf.d/${name}.htpasswd":
      ensure  => 'absent';
    }
  }
}

