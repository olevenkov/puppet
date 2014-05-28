#/etc/puppet/modules/ldapserver/manifests/init.pp

class ldapserver {
  package { "antlr": ensure=>installed }
  package { "idm-console-framework": ensure=>installed }
  package { "cyrus-sasl-gssapi": ensure=>installed }
  package { "cyrus-sasl-md5": ensure=>installed }
  package { "db4-utils": ensure=>installed }
  package { "java-1.6.0-openjdk": ensure=>installed }
  package { "ldapjdk": ensure=>installed }
  package { "mod_nss": ensure=>installed }
  package { "perl-Mozilla-LDAP": ensure=>installed }
  package { "jss": ensure=>installed }
}

class ldapserver::fedora-ds inherits ldapserver {
  package { "mozldap-tools": ensure=>installed }
  package { "389-admin": ensure=>installed }
  package { "389-admin-console": ensure=>installed }
  package { "389-admin-console-doc": ensure=>installed }
  package { "389-adminutil": ensure=>installed }
  package { "389-console": ensure=>installed }
  package { "389-ds": ensure=>installed }
  package { "389-ds-base": ensure=>installed }
  package { "389-ds-console": ensure=>installed }
  package { "389-ds-console-doc": ensure=>installed }
  package { "389-dsgw": ensure=>installed }
}

class ldapserver::rhel inherits ldapserver {
  package { "389-admin":              ensure=>"latest" }
  package { "389-admin-console":      ensure=>"latest" }
  package { "389-admin-console-doc":  ensure=>"latest" }
  package { "389-adminutil":          ensure=>"latest" }
  package { "389-console":            ensure=>"latest" }
  package { "389-ds-base":            ensure=>"latest" }
  package { "389-ds-base-libs":       ensure=>"latest" }
  package { "389-ds-console":         ensure=>"latest" }
  package { "389-ds-console-doc":     ensure=>"latest" }
  package { "389-dsgw":               ensure=>"latest" }
  package { "perl-Digest-SHA1":       ensure=>"latest" }
}

class ldapserver::education inherits ldapserver {
  include ldapserver::fedora-ds
}

class ldapserver::npg inherits ldapserver {
  include ldapserver::rhel
}


