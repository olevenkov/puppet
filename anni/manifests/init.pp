class anni($env) {
  include npd::php

  $user = $env ? {
    /live|test/  => 'anniclone',
    default => 'anni', 
  }
  
  $rootfolder = "/home/${user}/apps/${user}/current/src"
  
  $servername = $env ? {
    'live'    => 'live-anni.npd.nature.com',
    'sandbox' => 'anni.npd.nature.com',
    'test'    => 'test-anni.npd.nature.com',
    'staging' => 'staging-anni.npd.nature.com',
  }
  
  npd_application { $user:
    name => $user,
  }

  ssh::github { $user:
    public_key  => "puppet:///modules/anni/id_rsa.pub",
    private_key => "puppet:///modules/anni/id_rsa";
  }

  File {
    owner => $user,
    group => $user,
  }

  yumrepo { '10gen':
    descr    => '10gen Repository',
    baseurl  => 'http://downloads-distro.mongodb.org/repo/redhat/os/$basearch',
    enabled  => '1',
    gpgcheck => '0'
  }

  package { 'mongo-10gen-server':
    ensure  => present,
    require => Yumrepo['10gen']
  }

  file {
    "/opt/nginx-php/conf/sites_available/${user}.conf":
      ensure  => present,
      content => template("anni/nginx_conf.erb"),
      require => File['/opt/nginx-php/conf/sites_available'],
      notify  => Service['nginx-php'];

    "/opt/nginx-php/conf/sites_enabled/${user}.conf":
      ensure  => link,
      target  => "/opt/nginx-php/conf/sites_available/${user}.conf",
      notify  => Service['nginx-php'];

    "/home/${user}/apps/${user}/shared/config.php":
      ensure => present,
      source => [
        "puppet:///modules/anni/config.php.${env}",
        "puppet:///modules/anni/config.php"
      ];
    
    "/home/${user}/apps/${user}/shared/articles":
      ensure => directory;
    
    "/home/${user}/apps/${user}/shared/mongo.yml":
      ensure  => present,
      owner   => $user,
      group   => $user,
      source => [
        "puppet:///modules/anni/mongo.yml.${env}",
        "puppet:///modules/anni/mongo.yml"
      ];
      
    "/home/${user}/apps/${user}/shared/cron":
      ensure  => file,
      owner   => $user,
      group   => $user,
      mode   => 0777,
      source => "puppet:///modules/anni/cron.${user}";
    
    "/home/${user}/apps/${user}/shared/log/cron_log":
      ensure  => file,
      owner   => $user,
      group   => $user,
      mode   => 0644;
  }

  cron { "anni-old-articles-deleter":
    ensure => present,
    command => "/home/${user}/apps/${user}/shared/cron",
    user => $user,
    hour => "0"
  }
  
  # Hosts entries
  if $env == 'test' or $env == 'sandbox' {
    host { 'curi.npd.nature.com':
      ensure       => present,
      ip           => '192.168.88.222',
      host_aliases => 'curi.npd.nature.com',
    }
  }
}
