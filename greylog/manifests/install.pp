# Installs the Greylog user
#
# Maintainer: Chris Lowder <c.lowder@nature.com>
#
class greylog::install {
  deployable::user { 'greylog':
    deploy_continuously => true;
  }

  ssh::authorized_keys::web_apps { 'greylog': }

  ssh::github { 'greylog':
    public_key  => 'puppet:///modules/greylog/id_rsa.pub',
    private_key => 'puppet:///modules/greylog/id_rsa',
    ssh_config  => 'puppet:///modules/greylog/ssh_config',
  }

  runit::install_for_user { 'greylog':
    # See: http://www.elasticsearch.org/tutorials/2011/04/06/too-many-open-files.html
    max_open_files => 32000,
  }

  file {
    "/home/greylog/.bash_profile":
      ensure => 'present',
      mode   => "0644",
      owner  => 'greylog',
      group  => 'greylog',
      source => 'puppet:///modules/greylog/bash_profile';

    "/etc/logrotate.d/greylog":
      ensure  => present,
      content => template('npd_application/logrotate.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
  }
}

