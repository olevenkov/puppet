# modules/proftpd/manifests/server.pp

## Manage the proftpd service at NPG

class proftpd::server {
    # Defaults
  File {
    owner   => root,
    group   => root,
    mode    => 644,
    require => Package["proftpd"],
  }
    # Sourced from EPEL, resides on NPG repo, dependency is GeoIP (also on repo from epel)
  package { "proftpd":
    ensure => installed,
  }
  service { "proftpd":
    ensure    => running,
    enable    => true,
    subscribe => File["/etc/sysconfig/proftpd","/etc/proftpd.conf"],
    require   => Package["proftpd"],
  }
  file { "/etc/sysconfig/proftpd":
    source  => ["puppet:///modules/proftpd/proftpd.sysconfig.$::hostname", "puppet:///modules/proftpd/proftpd.sysconfig"],
  }
  file { "/etc/proftpd.conf":
    source => ["puppet:///modules/proftpd/proftpd.conf.$::hostname","puppet:///modules/proftpd/proftpd.conf"],
  }
    # There can be only one ftp server (:
  package { "vsftpd": 
    ensure => absent,
  }
}
