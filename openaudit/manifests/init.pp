class openaudit {

 include npgscripts
 file { "/usr/local/scripts/audit_linux-1.02.sh":
 source => "puppet:///modules/openaudit/audit_linux-1.02.sh",
  mode => 0754,
  owner => root,
  group => root,
}

  cron { "openaudit":
    command => "/usr/local/scripts/audit_linux-1.02.sh -Lo on -U http://192.168.88.36/openaudit/admin_pc_add_2.php",
    user    => "root",
    hour    => "6",
    minute  => "0",
    ensure  => present,

  }
}

