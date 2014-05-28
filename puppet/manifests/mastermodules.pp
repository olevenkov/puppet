#/etc/puppet/modules/puppet/manifests/mastermodules.pp

# Includes all the NPG module repos
class puppet::mastermodules {
  File {
    owner  => "puppet",
    user   => "puppet",
    ensure => "directory",
  }
  #These should somehow model hg repos but for now just create the directories and require manual clones
  file { ["/var/lib/puppet/modules","/var/lib/puppet/modules/it","/var/lib/puppet/modules/it-confidential","/var/lib/puppet/modules/npd","/var/lib/puppet/modules/platform"]:
    ensure => directory,
  }
}

