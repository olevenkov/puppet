# The default configuration is written to match what is installed by the 10gen package
#
# $log_path
#   Default: /var/log/mongo/mongod.log
#
# $dbpath
#   Default: /var/lib/mongo
class mongodb($logpath="/var/log/mongo/mongod.log", $dbpath="/var/lib/mongodb") {
  include mongodb::server

  file {
    "/etc/mongod.conf":
      ensure  => "file",
      owner   => "root",
      group   => "root",
      mode    => "755",
      content => template('mongodb/mongodb.conf.erb'),
      notify  => Service['mongod'],
      require => Package["mongo-10gen-server"];
  }
}

