#/etc/puppet/modules/php/manifests/configuration.pp

# Configure global php.ini variables by creating /etc/php.ini from a template.

class php::configuration($max_execution_time="30", $max_input_time="60", $upload_max_filesize="10M", $post_max_size="8M",$smtpserver="localhost") {
  file { "/etc/php.ini":
    content => template("php/php_ini.erb")
  }
}
