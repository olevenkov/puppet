class adgate {
  include npd::php

  npd_application { "adgate": name => "adgate" }

  ssh::github { 'adgate':
    public_key  => "puppet:///modules/adgate/id_rsa.pub",
    private_key => "puppet:///modules/adgate/id_rsa";
  }
  

  $servername = $hostname ? {
    "npd-sandbox"        => "adgate.npd.nature.com",
  }

  # Seeing as we're redefining (test-|staging-)?blogs.nature.com dns, we need to know the IPs to proxy-pass to.
  # This should be fixed better for live - we're only hitting one live node atm

  $railsblogs_upstream = $hostname ? {
    "npd-sandbox"        => "railsblogs-test",
  }

  $nginx_php_port = $hostname ? {
    "npd-sandbox"        => "6666",
    default              => "80",
  }

  file {
    "/opt/nginx-php/conf/sites_available/adgate.conf":
      ensure  => present,
      content => template("adgate/nginx_conf.erb"),
      require => File["/opt/nginx-php/conf/sites_available"],
      notify  => Service["nginx-php"];

    "/opt/nginx-php/conf/sites_enabled/adgate.conf":
      ensure  => link,
      target  => "/opt/nginx-php/conf/sites_available/adgate.conf",
      require => File["/opt/nginx-php/conf/sites_available/adgate.conf"],
      notify  => Service["nginx-php"];

    "/home/adgate/apps/adgate/shared/config":
      ensure  => directory,
      owner   => 'adgate',
      group   => 'adgate';

    "/home/adgate/apps/adgate/shared/uploads":
      ensure => link,
      target => "/mnt/fs/Web/NPG/adgate/uploads",
      owner  => 'adgate',
      group  => 'adgate';

    "/home/adgate/apps/adgate/shared/cache":
      ensure => link,
      target => "/mnt/fs/Web/NPG/adgate/cache",
      owner  => 'adgate',
      group  => 'adgate';


    "/home/adgate/apps/adgate/shared/wp-config.php":
      ensure => present,
      content => template('adgate/wp-config.erb'),
      owner  => 'adgate',
      group  => 'adgate';

    "/home/adgate/apps/adgate/shared/wp-cache-config.php":
      ensure => present,
      owner  => 'adgate',
      group  => 'adgate',
      mode   => "0666",
      source => [
        "puppet:///modules/adgate/wp-cache-config.php.$hostname",
        "puppet:///modules/adgate/wp-cache-config.php.$servergroup",
        "puppet:///modules/adgate/wp-cache-config.php",
      ];

    '/home/adgate/apps/adgate/shared/db-config.php':
      ensure  => present,
      owner   => 'adgate',
      group   => 'adgate',
      source  => [
        "puppet:///confidential/adgate/db-config.php.$hostname",
        "puppet:///confidential/adgate/db-config.php.$servergroup",
        'puppet:///confidential/adgate/db-config.php',
        "puppet:///modules/adgate/db-config.php.$hostname",
        "puppet:///modules/adgate/db-config.php.$servergroup",
        'puppet:///modules/adgate/db-config.php'
      ];
  }
}
