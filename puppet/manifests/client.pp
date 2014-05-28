#/etc/puppet/modules/puppet/manifests/client.pp
class puppet::client ( $puppetversion="2.6.12-2.el${lsbmajdistrelease}" ) {
  require yum::repo::nature
  package { 'puppet':
    ensure => $puppetversion,
  }

  file {
    "/etc/puppet/puppet.conf":
      owner  => "puppet",
      group  =>"puppet",
      mode   => 644,
      source => ["puppet:///modules/puppet/puppet.conf.$::hostname","puppet:///modules/puppet/puppet.conf"];
    "/etc/sysconfig/puppet":
      owner  => "root",
      group  => "root",
      mode   => 644,
      source => ["puppet:///modules/puppet/sysconfig.puppet.$::hostname", "puppet:///modules/puppet/sysconfig.puppet"];
    "/etc/sysconfig/puppet.conf":
      ensure => absent;
     }

  service { 'puppet':
    ensure    => running,
    enable    => true,
    subscribe => File["/etc/puppet/puppet.conf"],
  }
}

