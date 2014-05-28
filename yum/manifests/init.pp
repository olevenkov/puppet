# /etc/puppet/manifests/yum/init.pp
class yum::client {
  if ($operatingsystem == "RedHat") or ($operatingsystem == "CentOS") {
    case $lsbmajdistrelease {
      "4": { }
      default: {
        package { "yum": ensure => installed }
        include yum::repo::nature,yum::repo::rhnmirror
      }
    }
  }
}

# Better method of managing the nature repo, migrate to this.
class yum::repo::nature {
  yumrepo { 'Nature':
    descr    => "NPG Packages for RHEL \$releasever",
    baseurl  => "http://puppet.nature.com/rhel/\$releasever/\$basearch/",
    enabled  => '1',
    gpgcheck => '0',
  }
}

# Use a local mirror of RHN packages from cobbler
# This will downgrade the priority of your rhn plugin to prefer local updates
class yum::repo::rhnmirror {
  yumrepo { 'RHNMirror':
    descr   => "NPG Mirror of RHEL (Cobbler servers)",
    baseurl => $::operatingsystemrelease ? {
      /^6/    => "http://192.168.88.34/cobbler/repo_mirror/rhel-$::architecture-server-6",
      default => "http://192.168.4.40/cobbler/repo_mirror/rhel-$::architecture-server-5",
    },
    enabled  => 0,
    gpgcheck => 0,
    priority => 5,
  }
  file { "/etc/yum/pluginconf.d/rhnplugin.conf":
    source => "puppet:///modules/yum/rhnplugin.conf",
  }
}

# Deprecated method of managing the nature repo, remove this.
class yum::client::naturerepo {
    file { "/etc/yum.repos.d/nature.repo":
                owner   => "root",
                group   => "root",
                mode    => 640,
                source  => "puppet:///modules/yum/nature.repo",
        }
}

class yum::client::epel {
  if ($operatingsystem == "RedHat") or ($operatingsystem == "CentOS") {
    package { "epel-release": ensure => installed }
  }
}
