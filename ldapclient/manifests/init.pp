#/etc/puppet/modules/ldapclient/manifests/init.pp

class ldapclient {
  package { 
    authconfig: ensure => present;
    openldap: ensure   => present;
  }

    # RHEL 6 needs nss-pam-ldap
  case $operatingsystem {
    "RedHat","CentOS": {
      case $operatingsystemrelease {
        /^4(.*)/: { }
        /^5(.*)/: { }
        /^6(.*)/: { package { 'nss-pam-ldapd': ensure => installed } }
      }
    }
  }

  file {
    "/etc/openldap/cacerts/89bdfba5.0":
      ensure => present,
      owner  => root,
      group  => root,
      mode   => 644,
      source => ["puppet:///modules/ldapclient/certs/89bdfba5.0"];
    "/etc/openldap/cacerts/741a76b8.0":
      ensure => present,
      owner  => root,
      group  => root,
      mode   => 644,
      source => ["puppet:///modules/ldapclient/certs/741a76b8.0"];
    "/etc/openldap/cacerts/0031b113.0":
      ensure => present,
      owner  => root,
      group  => root,
      mode   => 644,
      source => ["puppet:///modules/ldapclient/certs/0031b113.0"];
    "/etc/ldap.conf":
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => 644,
      source  => [
                "puppet:///modules/ldapclient/ldap.conf.${hostname}",
                "puppet:///modules/ldapclient/ldap.conf"
            ],
      require => Package["openldap"];
    "/etc/sysconfig/authconfig":
      ensure => present,
      owner  => root,
      group  => root,
      mode   => 644,
      source => ["puppet:///modules/ldapclient/authconfig"];
    "/etc/security/access.conf":
      ensure=>present,
      owner=>root,
      group=>root,
      mode=>644,
      source=> [
        "puppet:///modules/ldapclient/access.conf.${hostname}",
        "puppet:///modules/ldapclient/access.conf.${servergroup}",
        "puppet:///modules/ldapclient/access.conf"
      ],
    }
    exec { "update-authconfig":
      command     => "/usr/sbin/authconfig --enableldap --enableldaptls --enableldapauth --disablenis --ldapserver=it-ldap1.nature.com,it-ldap2.nature.com --ldapbasedn=dc=nature,dc=com --enablemkhomedir --enablepamaccess --updateall",
        refreshonly => true,
        subscribe   => File["/etc/ldap.conf"],
        require     => [
        Package["authconfig"],
    File [
      "/etc/sysconfig/authconfig",
      "/etc/ldap.conf",
      "/etc/openldap/cacerts/741a76b8.0",
      "/etc/openldap/cacerts/89bdfba5.0",
      "/etc/openldap/cacerts/0031b113.0"
    ] ],
    }
}
