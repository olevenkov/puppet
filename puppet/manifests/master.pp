#/etc/puppet/modules/puppet/manifests/master.pp

# Relatively generic puppetmaster with passenger

## Note:  This requires that passenger be installed at a very specific location and version #
##  which matches the template.  Todo: clean this up and parameterize.
class puppet::master($puppetversion = '2.6.12-2.el5') {
  require yum::repo::nature
  include npgscripts
  package { 'puppet-server':
    ensure => "$puppet::master::puppetversion",
  }
  require ruby
  include apacheserver

  File {
    mode  => 644,
    owner => "root",
    group => "root",
  }
  file {
    "/etc/puppet/puppet.conf":
      source  => ["puppet:///modules/puppet/puppet.conf.$::hostname","puppet:///modules/puppet/master.puppet.conf"],
      require => Package["puppet-server"];
    "/etc/puppet/fileserver.conf":
      source => ["puppet:///modules/puppet/fileserver.conf.$::hostname", "puppet:///modules/puppet/fileserver.conf"];
    "/etc/puppet/auth.conf":
      source => ["puppet:///modules/puppet/auth.conf.$::hostname", "puppet:///modules/puppet/auth.conf"];
    "/etc/puppet/manifests/nodes.pp":
      source => ["puppet:///modules/puppet/nodes.pp.$::hostname", "puppet:///modules/puppet/nodes.pp"];
    "/etc/puppet/manifests/site.pp":
      source => ["puppet:///modules/puppet/site.pp.$::hostname", "puppet:///modules/puppet/site.pp"];
    "/etc/puppet/manifests/modules.pp":
      source => ["puppet:///modules/puppet/modules.pp.$::hostname", "puppet:///modules/puppet/modules.pp"];
  }

  file { "/usr/local/scripts/find-host-record-in-puppet.rb":
    source  => ["puppet:///modules/puppet/find-host-record-in-puppet.rb"],
    require => File["/usr/local/scripts"],
    mode    => 754,
    owner   => root,
    group   => root,
  }

    # Don't manage apache passenger file as the gem installation is problematic; run the service alone for now.
  #file { "/etc/httpd/conf.d/puppetmasterd.conf":
  #  content => template("puppet/puppetmaster.conf.erb"),
  #  notify  => Service["httpd"],
  #}
  file { ["/etc/puppet/rack","/etc/puppet/rack/public"]:
    ensure => directory,
    owner  => "puppet",
    group  => "apache",
    mode   => 755,
  }
  file { "/etc/puppet/rack/config.ru":
    owner   => "puppet",
    group   => "apache",
    mode    => 755,
    content => template("puppet/puppetmaster-config.ru.erb"),
    require => File["/etc/puppet/rack"],
  }
  #  service { "puppetmaster":
  #  ensure    => running,
  #  enable    => true,
  #  require   => File["/etc/puppet/puppet.conf"],
  #  subscribe => [Package["puppet-server"],File["/etc/puppet/puppet.conf"]],
  #}
    # Passenger needs a newer ruby which we aren't going to tackle here.
  #  package { "passenger":
  #  ensure   => "3.0.8",
  #  provider => gem,
  #  require  => Package["rubygems"],
  #}


  file {
    '/etc/logrotate.d/puppet':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      source => 'puppet:///modules/puppet/logrotate.d/puppet';
  }
}

