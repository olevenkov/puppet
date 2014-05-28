#/etc/puppet/modules/apacheserver/manifests/pagespeed.pp

# Manage mod_pagespeed  See IT-11627
class apacheserver::pagespeed {
  include apacheserver
  require rhel-basepkgs
  package { "mod-pagespeed-beta":
    ensure => installed,
  }

  file { "/etc/httpd/conf.d/pagespeed.conf":
    source => ["puppet:///modules/apacheserver/pagespeed.conf.${hostname}",
	"puppet:///modules/apacheserver/pagespeed.conf.${servergroup}",
      "puppet:///modules/apacheserver/pagespeed.conf"],
    notify  => Service["httpd"],
    require => Package["mod-pagespeed-beta"],
  }
}
class apacheserver::livepagespeed {
  include apacheserver
  require rhel-basepkgs
  package { "mod-pagespeed-beta":
    ensure => installed,
  }

  file { "/etc/httpd/conf/pagespeed.conf":
    source => ["puppet:///modules/apacheserver/pagespeed.conf.${hostname}",
	"puppet:///modules/apacheserver/pagespeed.conf.${servergroup}"],
    notify  => Service["httpd"],
    require => Package["mod-pagespeed-beta"],
  }
}
