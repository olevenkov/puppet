#
# Installs NGINX from the official NGINX repository, to be used as a simple
# proxy for other services.
#
# For details on setting up and configuring virtual hosts, please look at
# the nginx::vhost definition.
#
# Maintained by Darren Oakley (d.oakley@nature.com)
#           and Luca Belmondo (l.belmondo@nature.com)
#
class nginx {
  include nginx::install
  include nginx::service

  Class['nginx::install'] -> Class['nginx::service']
}

