# Note: Unsecure, _must_ _install_ _Hiera_
class mysql_configs::webistrano {
  class { 'mysql::server':
    config_hash => { 'root_password' => '*************' };
  }

  class { 'mysql::backup':
    backupuser     => 'backup',
    backuppassword => '**********************',
    backupdir      => '/tmp/backups',
    ensure         => 'present',
    require         => Class['mysql::server'];
  }

  mysql::db { 'webistrano_production':
    user     => 'webistrano',
    password => '****************',
    require  => Class['mysql::server'];
  }
}
