#/etc/puppet/modules/redis/manifests/init.pp

# This redis install is dependent on the redis RPMs built
# by this project: https://github.com/nature/fpm-recipes

class redis {
  package { 'redis-server': ensure => present }
  service { 'redis':
    ensure     => running,
    name       => 'redis',
    hasstatus  => true,
    hasrestart => true,
    require    => Package['redis-server'],
    subscribe  => File['/etc/redis/redis.conf']
  }
}

