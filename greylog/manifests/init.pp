class greylog {
  include greylog::install
  include greylog::elasticsearch
  include greylog::web
  include greylog::server

  Class['greylog::install'] -> Class['greylog::web']
  Class['greylog::install'] -> Class['greylog::server']
  Class['greylog::install'] -> Class['greylog::elasticsearch']

  class { 'greylog::landing':
    ensure => 'absent';
  }

  # Note: This probably shouldn't be here...
  class { mongodb:
    dbpath  => '/data/mongodb',
    require => File['/data/mongodb'];
  }

  file {
    ['/data/', '/data/mongodb']:
      ensure => directory,
      owner  => "mongod",
      group  => "mongod",
      mode   => '0755';
  }
}

