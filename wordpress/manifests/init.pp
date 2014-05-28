class wordpress::base {
    package { "httpd" : ensure => installed }

    exec { "Download-wp" :
                cwd => "/usr/local/src",
                command => "/usr/bin/wget http://puppet.nature.com/tarballs/wordpress-3.1.2.tar.gz",
                creates => "/usr/local/src/wordpress-3.1.2.tar.gz",
    requires => [
      Package["httpd"]
      ]
            }
    exec { "Basedir-wp" :
                cwd => "/var/www",
                command => "/bin/tar zxf /usr/local/src/wordpress-3.1.2.tar.gz && mv /var/www/wordpress /var/www/wordpress-3.1.2-base",
                creates => "/var/www/wordpress-3.2.1-base",
                require => [
                        Exec["Download-wp"]
                        ]
      }
}

class wordpress::bts inherits wordpress::base {
#
# $servergroup
#

    exec { "Basedir-bts" :
                cwd => "/var/www",
                command => "cp -fR wordpress-3.1.2-base $servergroup-bts-wp.nature.com",
                creates => "/var/www/$servergroup-bts-wp.nature.com",
                require => [
                        Exec["Basedir-wp"],
                        ]
            }

}
