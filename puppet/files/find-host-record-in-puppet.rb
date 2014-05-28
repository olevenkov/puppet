#!/usr/bin/ruby

# File:      yaml_store_search.rb
#
# Description:  A script to search through your puppet master's YAML store
#         for a specific node's data.
# Original source: http://puppetlabs.com/blog/puppet-mcollective-make-for-quick-inventory-queries-part-2-of-2/

# Modified 12/2011 Scott McCool
## Simplified input (only takes hostname to search for)
## Restricted output to some key facts (use mco inventory if you want them all)
## Require root

raise "Must run as root" unless Process.uid==0

require 'puppet'
 
Puppet.settings.parse

if not ARGV[0] or ARGV[0] == '--help'
  puts "find-host-record:  Searches through the puppet yaml data for a hostname or IP address."
  puts "Usage: ./find-host-record <hostname|ip>"
  exit(1)
end

$hn=ARGV[0] 
 
# Iterate through your puppet YAML store using the $vardir from
#  your puppet.conf settings. If we find the YAML file with a
#  matching certname or hostname, break out of the loop.
Dir.glob("#{Puppet[:vardir]}/yaml/facts/*") {|file|
  $tf = YAML::load_file(file).values
  if $tf['fqdn'] =~ /#{$hn}/ or $tf['certname'] =~ /#{$hn}/ or $tf['ipaddress'] =~ /#{$hn}/
    puts "Match! According to puppet: \n\thostname: #{$tf['hostname']} is a #{$tf['virtual']} machine running #{$tf['operatingsystem']} version #{$tf['operatingsystemrelease']}.\n\tIt's primary IP is probably #{$tf['ipaddress']}.\n\tRecord last updated at #{YAML::load_file(file).expiration}."
  end
}
