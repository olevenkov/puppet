#
# Redis built from source... Please do not use this for new deploys
#

## May have additional ruby dependencies!
##  This is a binary built from:
##   82  wget http://rubyforge.org/frs/download.php/60718/rubygems-1.3.5.tgz
##   83  tar zxvf rubygems-1.3.5.tgz
##   84  cd rubygems-1.3.5
##   85  ruby setup.rb
##  132  wget http://redis.googlecode.com/files/redis-2.0.0-rc4.tar.gz
##  133  tar zxvf redis-2.0.0-rc4.tar.gz
##  134  cd redis-2.0.0-rc4
##  140  make

class redis::from_source {
  group { 'redis':
    ensure => present,
    gid    => '59825',
  }

  user { 'redis':
    ensure  => present,
    uid     => '59825',
    gid     => '59825',
    comment => 'Redis user',
    home    => '/tmp',
    shell   => '/bin/bash',
  }

  file {
    '/etc/init.d/redis':
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => [
        "puppet:///modules/redis/redis.init.$hostname",
        "puppet:///modules/redis/redis.init.$servergroup",
        'puppet:///modules/redis/redis.init'
      ];
    '/etc/redis.conf':
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => [
        "puppet:///modules/redis/redis.conf.$hostname",
        "puppet:///modules/redis/redis.conf.$servergroup",
        'puppet:///modules/redis/redis.conf'
      ];
    '/usr/bin/redis-server':
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => ['puppet:///modules/redis/redis-server'];
    '/usr/bin/redis-cli':
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => ['puppet:///modules/redis/redis-cli'];
    '/var/log/redis.log':
      owner  => 'redis',
      group  => 'redis',
      mode   => '0644';
    '/var/db/redis':
      ensure => directory,
      owner  => 'redis',
      group  => 'redis',
      mode   => '0750';
  }

  service { 'redis':
    ensure    => 'running',
    name      => 'redis',
    hasstatus => true,
    require   => [
      File[
        '/etc/init.d/redis',
        '/var/log/redis.log',
        '/usr/bin/redis-server',
        '/var/db/redis'
      ],
      User['redis'],
      Group['redis']
    ],
  }
}

