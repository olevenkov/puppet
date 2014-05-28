#/etc/puppet/modules/puppet/manifests/package.pp

# Legacy implementation, just assume they want to be a client

class puppet::package {
  class { 'puppet::client': }
}
