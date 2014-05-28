#/etc/puppet/modules/ruby/init.pp

# Manage ruby basics from epel
class ruby {
  require yum::client::epel
  package { ['ruby','rubygems','ruby-devel']:
    ensure => installed,
  }
}
