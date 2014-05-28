# site.pp for ec2 puppetmaster

## Concept:  Nodes are defined by a custom fact, npg_role and include relevent classes based solely on roll

## Todo:  Lookup and use proper run stages?

  ## Stuff we always want
include npgbase::scripts, npgbase::users, motd, npgbase::packages, ec2base, zenoss::client
include mcollective::client

case $::npg_role {
  "demo": {
      ## All singing, all dancing EC2 demo mode.  Watch me spring to live and fire up any
      ## service you want to test.  I may be useless, but at least I'm purty.
      include natureapps::whodemo
  }
  "loadbalancer": {
    include loadbalancer
  }
  "npgweb": {
    include varnish::npgweb # TODO: Should register itself with loadbalancer/haproxy
    include nginx::static   # A base nginx install with a status page for demo
  }
  "npgapp": {
      # TODO: Should register itself with npgweb
    jetty::packagenew { "jetty-npg":
      name    => "jetty-npg",
      version => "6.1.26",
      port    => "7280",
    }
    include natureapps::jetty-npg
  }
  "npgmysql": {
    # This will probably be an RDS store; spec it out.
  }
  "npgfs": {
    # Figure out how we're doing fileservers in ec2!
  }
  default: {
    # Role has not yet been defined... Should probably fire off a message/error since this is
    # going to be a waste of money!
    notice("I have no npg_role defined.  Such a waste.")
  }
}
