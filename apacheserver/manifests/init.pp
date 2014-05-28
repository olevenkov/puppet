#/etc/puppet/modules/apacheserver/manifests/init.pp

#All apache servers need the package and our logrotate script.
class apacheserver($ensure='present') {

  if $ensure == 'present' {
    include apacheserver::install
  } elsif $ensure == 'absent' {
    include apacheserver::remove
  } else {
    fail "'$ensure' is not supported. Please use 'present' or 'absent'."
  }
}

class apacheserver::install {
  include npgscripts
  package { 'httpd': ensure=>installed }
  file { '/usr/local/scripts/rotatehttpd.sh':
    require => File['/usr/local/scripts'],
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    source  => ['puppet:///modules/apacheserver/rotatehttpd.sh'],
  }
  cron { 'rotatehttpd':
    command => '/usr/local/scripts/rotatehttpd.sh',
    user    => 'root',
    hour    => '0',
    minute  => '0',
    require => File['/usr/local/scripts/rotatehttpd.sh'],
  }
  file { '/etc/httpd/conf.d/vhosts/':
    ensure  => directory,
    require => Package['httpd'],
  }
  service { 'httpd':
    ensure    => running,
    name      => 'httpd',
    enable    => true,
    hasstatus => true,
    require   => Package['httpd'],
    subscribe => [
      Package['httpd'] ,
    ];
  }
}

class apacheserver::vhostconfig {
  include apacheserver
  file { "/etc/httpd/conf.d/vhostsubdirs.conf":
    content => "Include /etc/httpd/conf.d/vhosts/*",
    require => Package["httpd"],
    notify  => Service["httpd"],
  }
}
# Define a vhost which will be used to generate a vhosts/<name>.conf file 
# Can pass in a different template, but the base will include most of what we do (access control, redirects, proxyconfig)
# Todo:  Modify /etc/httpd/conf.d/vhosts.conf to include vhosts/* , currently left as a manual step.
define apacheserver::vhost($port="80",$basedir="/var/www/${name}",$docroot="/var/www/${name}/htdocs",$template="apacheserver/vhost.erb",$serveraliases="",$priority="99",$acblock="",$proxyblock="",$redirblock="") {
  include apacheserver, apacheserver::vhostconfig
  file { "/etc/httpd/conf.d/vhosts/${priority}-${name}": 
    content => template($template),
    owner   => 'root',
    group   => 'root',
    mode    => '644',
    notify  => Service["httpd"],
  }
  file { "${basedir}":
    ensure => directory,
    require => File["/etc/httpd/conf.d/vhosts/${priority}-${name}"],
    notify => Service["httpd"],
  }
  file { ["${docroot}","${basedir}/logs"]:
    ensure => directory,
    require => File["${basedir}"],
  }
}



class ejpapacheserver {
    package { "httpd": ensure=>installed }

    file {
        "/usr/local/scripts/rotatehttpd-ejp.sh":
            owner   => "root",
            group   => "root",
            mode    => 750,
            source  => ["puppet:///modules/apacheserver/rotatehttpd-ejp.sh"],
            require => File["/usr/local/scripts"];
        "/etc/sysconfig/httpd":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => ["puppet:///modules/apacheserver/ejp/httpd"],
            notify  => Service["httpd"],
            require => Package["httpd"];
        "/etc/httpd/conf/httpd.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/ejp/httpd.conf.$hostname",
                "puppet:///modules/apacheserver/ejp/httpd.conf.$servergroup",
                "puppet:///modules/apacheserver/ejp/httpd.conf"
            ],
            notify  => Service["httpd"],
            require => Package["httpd"];
        "/etc/httpd/conf.d/vhosts.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/ejp/vhosts.conf.$hostname",
                "puppet:///modules/apacheserver/ejp/vhosts.conf.$servergroup",
                "puppet:///modules/apacheserver/ejp/vhosts.conf"
            ],
            notify  => Service["httpd"],
            require => Package["httpd"];
        "/etc/httpd/conf.d/f5check.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            content => template("apacheserver/f5check.erb"),
            notify  => Service["httpd"],
            require => [ Package["httpd"], File["/var/www/html/logs"] ];
        "/etc/httpd/conf/redirects.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/ejp/redirects.conf.$hostname",
                "puppet:///modules/apacheserver/ejp/redirects.conf.$servergroup",
                "puppet:///modules/apacheserver/ejp/redirects.conf"
            ],
            notify  => Service["httpd"],
            require => Package["httpd"];
        "/var/www/html/logs": ensure => directory;
    }

    cron { "rotatehttpd-ejp":
        command => "/usr/local/scripts/rotatehttpd-ejp.sh",
        user => "root",
        hour => "0",
        minute => "0",
        require => File["/usr/local/scripts/rotatehttpd-ejp.sh"],
    }

    service { "httpd":
        name      => "httpd",
        ensure    => running,
        enable    => true,
        hasstatus => true,
        require   => Package["httpd"],
        subscribe => [
            Package["httpd"],
            ];
    }
}

#Generic recipe to manage httpd.conf and vhosts.conf as well as the service
class apacheserver::generic inherits apacheserver {
    file { 
        "/etc/httpd/conf/httpd.conf":
            owner   => "root",
        group   => "root",
        mode    => 644,
          source  => ["puppet:///modules/apacheserver/$hostname/httpd.conf"],
          require => Package["httpd"];
      "/etc/httpd/conf.d/vhosts.conf":
          owner   => "root",
        group   => "root",
        mode    => 644,
          source  => ["puppet:///modules/apacheserver/$hostname/vhosts.conf"],
          require => Package["httpd"];
    }
}


#NPG-j2ee servers (test/staging/live)
class apacheserver::j2ee inherits apacheserver {
    if ( $servergroup == 'staging' ) {
      file {
      "/etc/httpd/conf.d/vhosts.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            content => template("apacheserver/staging-j2ee-vhosts.conf.erb"),
            require => Package["httpd"],
            notify  => Service["httpd"]
      }
    }
    else {
      file {
      "/etc/httpd/conf.d/vhosts.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/j2ee/vhosts.conf.$hostname",
                "puppet:///modules/apacheserver/j2ee/vhosts.conf.$servergroup",
                "puppet:///modules/apacheserver/j2ee/vhosts.conf",
            ],
            require => Package["httpd"],
            notify  => Service["httpd"]
      }
    }

    file { 
      "/etc/httpd/conf/httpd.conf":
          owner   => "root", 
        group   => "root", 
        mode    => 644,
          source  => [
          "puppet:///modules/apacheserver/j2ee/httpd.conf.$hostname", 
          "puppet:///modules/apacheserver/j2ee/httpd.conf.$servergroup",
          "puppet:///modules/apacheserver/j2ee/httpd.conf"
          ],
        require => Package["httpd"],
        notify  => Service["httpd"];
        "/etc/httpd/conf/network-redirects.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/j2ee/network-redirects.conf.$hostname",
                "puppet:///modules/apacheserver/j2ee/network-redirects.conf.$servergroup",
                "puppet:///modules/apacheserver/j2ee/network-redirects.conf"
            ] ,
            require => Package["httpd"],
            notify  => Service["httpd"];
        "/etc/httpd/conf/palgrave_redirects.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/j2ee/palgrave_redirects.conf.$hostname",
                "puppet:///modules/apacheserver/j2ee/palgrave_redirects.conf.$servergroup",
                "puppet:///modules/apacheserver/j2ee/palgrave_redirects.conf"
            ] ,
            require => Package["httpd"],
            notify  => Service["httpd"];
        "/etc/httpd/conf/palgraveconnect_redirects.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/j2ee/palgraveconnect_redirects.conf.$hostname",
                "puppet:///modules/apacheserver/j2ee/palgraveconnect_redirects.conf.$servergroup",
                "puppet:///modules/apacheserver/j2ee/palgraveconnect_redirects.conf"
            ] ,
            require => Package["httpd"],
            notify  => Service["httpd"];
        "/etc/httpd/conf/rdfredirects.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/j2ee/rdfredirects.conf.$hostname",
                "puppet:///modules/apacheserver/j2ee/rdfredirects.conf.$servergroup",
                "puppet:///modules/apacheserver/j2ee/rdfredirects.conf"
            ] ,
            require => Package["httpd"],
            notify  => Service["httpd"];
        "/etc/httpd/conf/redirects.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/j2ee/redirects.conf.$hostname",
                "puppet:///modules/apacheserver/j2ee/redirects.conf.$servergroup",
                "puppet:///modules/apacheserver/j2ee/redirects.conf"
            ] ,
            require => Package["httpd"],
            notify  => Service["httpd"];
        "/etc/httpd/conf/rssredirects.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/j2ee/rssredirects.conf.$hostname",
                "puppet:///modules/apacheserver/j2ee/rssredirects.conf.$servergroup",
                "puppet:///modules/apacheserver/j2ee/rssredirects.conf"
            ] ,
            require => Package["httpd"],
            notify  => Service["httpd"];
        "/etc/httpd/conf/secure-redirects.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/j2ee/secure-redirects.conf.$hostname",
                "puppet:///modules/apacheserver/j2ee/secure-redirects.conf.$servergroup",
                "puppet:///modules/apacheserver/j2ee/secure-redirects.conf"
            ] ,
            require => Package["httpd"],
            notify  => Service["httpd"];
        "/etc/httpd/conf/set_header.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/j2ee/set_header.conf.$hostname",
                "puppet:///modules/apacheserver/j2ee/set_header.conf.$servergroup",
                "puppet:///modules/apacheserver/j2ee/set_header.conf"
            ] ,
            require => Package["httpd"];
        "/etc/httpd/conf/cache.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/j2ee/cache.conf.$hostname",
                "puppet:///modules/apacheserver/j2ee/cache.conf.$servergroup",
                "puppet:///modules/apacheserver/j2ee/cache.conf"
            ] ,
            require => Package["httpd"];
    }
      # These files shouldn't be auto-included and are managed in conf/ above, conf.d is the wrong location.  See IT-12024
    file { ["/etc/httpd/conf.d/cache.conf","/etc/httpd/conf.d/network-redirects.conf","/etc/httpd/conf.d/palgrave_redirects.conf","/etc/httpd/conf.d/rdfredirects.conf","/etc/httpd/conf.d/redirects.conf","/etc/httpd/conf.d/rssredirects.conf","/etc/httpd/conf.d/secure-redirects.conf","/etc/httpd/conf.d/set_header.conf"]:
      ensure => absent,
    }
}


class apacheserver::rsuite inherits apacheserver {
    file { 
      "/etc/httpd/conf/httpd.conf":
          owner   => "root", 
        group   => "root", 
          mode    => 644,
          source  => [
          "puppet:///modules/apacheserver/rsuite/httpd.conf.$hostname",
          "puppet:///modules/apacheserver/rsuite/httpd.conf.$servergroup",
          "puppet:///modules/apacheserver/rsuite/httpd.conf"
          ],
        require => Package["httpd"];
      "/etc/httpd/conf.d/vhosts.conf":
          owner   => "root", 
        group   => "root", 
        mode    => 644,
          source  => [
          "puppet:///modules/apacheserver/rsuite/vhosts.conf.$hostname",
          "puppet:///modules/apacheserver/rsuite/vhosts.conf.$servergroup",
          "puppet:///modules/apacheserver/rsuite/vhosts.conf"
      ],
          require => Package["httpd"];
    }
}


class apacheserver::polopoly inherits apacheserver {
    file { 
      "/etc/httpd/conf/httpd.conf":
          owner   => "root", 
        group   => "root", 
        mode    => 644,
          notify  => Service["httpd"],
          source  => [
          "puppet:///modules/apacheserver/polopoly/httpd.conf.$hostname", 
          "puppet:///modules/apacheserver/polopoly/httpd.conf"
        ],
          require => Package["httpd"];
        "/etc/httpd/conf/authblock.conf":
            owner   => "root", 
        group   => "root", 
        mode    => 644,
          source  => ["puppet:///modules/apacheserver/polopoly/authblock.conf"],
          require => Package["httpd"];
      "/etc/httpd/conf.d/vhosts.conf":
          owner   => "root", 
        group   => "root", 
        mode    => 644,
        notify  => Service["httpd"],
          source  => [
      "puppet:///modules/apacheserver/polopoly/vhosts.conf.$hostname", 
      "puppet:///modules/apacheserver/polopoly/vhosts.conf.$servergroup",
          "puppet:///modules/apacheserver/polopoly/vhosts.conf"
      ],
            require => Package["httpd"];
        "/var/www/html": 
        ensure => directory;
      "/var/www/html/robots.txt": 
          owner   =>"root",
        group   =>"root",
        mode    => 755,
          source  => [
      "puppet:///modules/apacheserver/polopoly/robots.txt.$hostname",
          "puppet:///modules/apacheserver/polopoly/robots.txt"
      ],
          require => Package["httpd"];
      "/var/www/html/favicon.ico":
          owner   => "root",
        group   => "root",
        mode    => 755,
          source  => ["puppet:///modules/apacheserver/polopoly/favicon.ico"],
          require => Package["httpd"];
    }
}

class apacheserver::nated inherits apacheserver {
    if ( $servergroup == 'live' ) {
      file {
      "/etc/httpd/conf.d/vhosts.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            content => template("apacheserver/education-live-vhosts.conf.erb"),
            require => Package["httpd"],
            notify  => Service["httpd"]
      }
    }
    else {
      file {
      "/etc/httpd/conf.d/vhosts.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            content => template("apacheserver/education-staging-vhosts.conf.erb"),
            require => Package["httpd"],
            notify  => Service["httpd"]
      }
    }
    file {
        "/etc/mime.types":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/scitable/mime.types.$hostname",
                "puppet:///modules/apacheserver/scitable/mime.types.$servergroup",
                "puppet:///modules/apacheserver/scitable/mime.types",
            ],
            notify  => Service["httpd"];
        "/etc/httpd/conf/httpd.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/scitable/httpd.conf.$hostname",
                "puppet:///modules/apacheserver/scitable/httpd.conf.$servergroup",
                "puppet:///modules/apacheserver/scitable/httpd.conf",
            ],
            require => Package["httpd"],
            notify  => Service["httpd"];
        "/var/www/html":
            ensure => directory;
        "/etc/httpd/conf.d/natedUrlRewrite_modified.cfg":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/scitable/natedUrlRewrite_modified.cfg.$hostname",
                "puppet:///modules/apacheserver/scitable/natedUrlRewrite_modified.cfg.$servergroup",
                "puppet:///modules/apacheserver/scitable/natedUrlRewrite_modified.cfg",
            ],
            require => Package["httpd"],
            notify  => Service["httpd"];
        "/etc/httpd/conf.d/natureeducation_microsite.cfg":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/scitable/natureeducation_microsite.cfg.$hostname",
                "puppet:///modules/apacheserver/scitable/natureeducation_microsite.cfg.$servergroup",
                "puppet:///modules/apacheserver/scitable/natureeducation_microsite.cfg",
            ],
            require => Package["httpd"],
            notify  => Service["httpd"];
        "/etc/httpd/conf.d/principles_urlrewrite.cfg":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/scitable/principles_urlrewrite.cfg.$hostname",
                "puppet:///modules/apacheserver/scitable/principles_urlrewrite.cfg.$servergroup",
                "puppet:///modules/apacheserver/scitable/principles_urlrewrite.cfg",
            ],
            require => Package["httpd"],
            notify  => Service["httpd"];
    }
}

class apacheserver::ejp inherits ejpapacheserver {
    file {
        "/var/www/pool1": ensure => directory;
        "/var/www/pool1/logs": ensure => directory, require => File["/var/www/pool1"];
        "/var/www/pool2": ensure => directory;
        "/var/www/pool2/logs": ensure => directory, require => File["/var/www/pool2"];
        "/var/www/pool3": ensure => directory;
        "/var/www/pool3/logs": ensure => directory, require => File["/var/www/pool3"];
        "/var/www/pool4": ensure => directory;
        "/var/www/pool4/logs": ensure => directory, require => File["/var/www/pool4"];
        "/var/www/pool5": ensure => directory;
        "/var/www/pool5/logs": ensure => directory, require => File["/var/www/pool5"];
        "/var/www/pool6": ensure => directory;
        "/var/www/pool6/logs": ensure => directory, require => File["/var/www/pool6"];
        "/var/www/pool7": ensure => directory;
        "/var/www/pool7/logs": ensure => directory, require => File["/var/www/pool7"];
        "/var/www/pool8": ensure => directory;
        "/var/www/pool8/logs": ensure => directory, require => File["/var/www/pool8"];
    }
}

class apacheserver::ejpspd inherits ejpapacheserver {
    file {
        "/var/www/spd": ensure => directory;
        "/var/www/spd/logs": ensure => directory, require => File["/var/www/spd"];
    }
}


class apacheserver::services inherits apacheserver {
    file {
        "/etc/httpd/conf/httpd.conf":
                owner   => "root",
                group   => "root",
                mode    => 644,
                source  => [
                        "puppet:///modules/apacheserver/services/httpd.conf.$hostname",
                        "puppet:///modules/apacheserver/services/httpd.conf.$servergroup",
                        "puppet:///modules/apacheserver/services/httpd.conf"
                        ],
                notify  => Service["httpd"],
                require => Package["httpd"];
        "/etc/httpd/conf.d/vhosts.conf":
                owner   => "root",
                group   => "root",
                mode    => 644,
                source  => [
                        "puppet:///modules/apacheserver/services/vhosts.conf.$hostname",
                        "puppet:///modules/apacheserver/services/vhosts.conf.$servergroup",
                        "puppet:///modules/apacheserver/services/vhosts.conf"
                        ],
                notify  => Service["httpd"],
                require => Package["httpd"];
    }
}

class apacheserver::ejpreport inherits apacheserver {
    file {
        "/var/www/ejpreport": ensure => directory;
  "/var/www/ejpreport/logs": ensure => directory, require => File["/var/www/ejpreport"];
  "/etc/httpd/conf/httpd.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/ejp/httpd.conf.$hostname"
            ],
            require => Package["httpd"];
        "/etc/httpd/conf.d/vhosts.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/ejp/vhosts.conf.$hostname"
            ],
            require => Package["httpd"];
    }
}

class apacheserver::wordpress inherits apacheserver {
    file {
  "/etc/httpd/conf.d/vhosts.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/wordpress/vhosts.conf.$servergroup"
            ],
            require => Package["httpd"];
  }
}

class apacheserver::external inherits apacheserver {
    file {
        "/etc/httpd/conf.d/vhosts.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/external/vhosts.conf.$servergroup"
            ],
            require => Package["httpd"];
        }

}

class apacheserver::sciamblogs inherits apacheserver {
    file {
      "/etc/httpd/conf/httpd.conf":
          owner   => "root",
        group   => "root",
          mode    => 644,
          source  => [
          "puppet:///modules/apacheserver/prod-blogs-sa/httpd.conf.$hostname",
          "puppet:///modules/apacheserver/prod-blogs-sa/httpd.conf.$servergroup",
          "puppet:///modules/apacheserver/prod-blogs-sa/httpd.conf"
          ],
        require => Package["httpd"];
      "/etc/httpd/conf.d/vhosts.conf":
          owner   => "root",
        group   => "root",
        mode    => 644,
          source  => [
          "puppet:///modules/apacheserver/prod-blogs-sa/vhosts.conf.$hostname",
          "puppet:///modules/apacheserver/prod-blogs-sa/vhosts.conf.$servergroup",
          "puppet:///modules/apacheserver/prod-blogs-sa/vhosts.conf"
      ],
          require => Package["httpd"];
    }
}
class apacheserver::integral inherits apacheserver {
    file {
        "/etc/httpd/conf/httpd.conf":
                owner   => "root",
                group   => "root",
                mode    => 644,
                source  => [
                        "puppet:///modules/apacheserver/integral/httpd.conf.$hostname",
                        "puppet:///modules/apacheserver/integral/httpd.conf.$servergroup",
                        ],
                require => Package["httpd"];
        "/etc/httpd/conf.d/vhosts.conf":
                owner   => "root",
                group   => "root",
                mode    => 644,
                source  => [
                        "puppet:///modules/apacheserver/integral/vhosts.conf.$hostname",
                        "puppet:///modules/apacheserver/integral/vhosts.conf.$servergroup",
                        ] ,
                require => Package["httpd"];
    }
}
class apacheserver::datastore inherits apacheserver {
    file {
        "/etc/httpd/conf.d/vhosts.conf":
            owner   => "root",
            group   => "root",
            mode    => 644,
            source  => [
                "puppet:///modules/apacheserver/datastore/vhosts.conf.$hostname",
                "puppet:///modules/apacheserver/datastore/vhosts.conf.$servergroup"
            ],
            require => Package["httpd"];
        }

}

