class puppet::hiera($version='0.2.0') {
  require ruby
  File {
    owner => 'root',
    group => 'root',
  }
  package {
    'hiera-puppet':
      ensure   => $version,
      provider => gem,
      require  => Package['rubygems'];
  }

  exec { 'install-hiera-puppet':
    command => "/bin/cp -r /usr/local/lib/ruby/gems/1.8/gems/hiera-puppet-${version}/lib/puppet /var/lib/puppet/lib/puppet",
    creates => '/var/lib/puppet/lib/puppet/parser/functions/hiera.rb',
    require => Package['hiera-puppet'],
  }

  file {
    '/etc/puppet/hiera.yaml':
      source  => 'puppet:///modules/puppet/hiera.yaml';
    '/etc/hiera.yaml':
      ensure  => symlink,
      target  => '/etc/puppet/hiera.yaml',
      require => File["/etc/puppet/hiera.yaml"];
    '/etc/puppet/hieradata':
      ensure  => directory;
        # Apply the patch to Hiera-Puppet that enables the use of $calling_module
        # and $calling_class.
    "/usr/local/lib/ruby/gems/1.8/gems/hiera-puppet-${version}/lib/hiera/scope.rb":
      source  => 'puppet:///modules/puppet/scope.rb',
      require => Package['hiera-puppet'];
  }
}
