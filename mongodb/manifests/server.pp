class mongodb::server {
  package { "mongo-10gen-server":
    ensure => installed,
  }
  service { "mongod":
    ensure     => running,
    enable     => true,
    hasrestart => true,
    restart    => '/sbin/service mongod stop && /sbin/service mongod start',
    require    => Package["mongo-10gen-server"],
  }
}
