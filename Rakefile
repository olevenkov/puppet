require 'rubygems'
require 'bundler/setup'

Bundler.require

require 'rake'
require 'rspec/core/rake_task'
require 'puppet-lint/tasks/puppet-lint'

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ['--color', '--format documentation']
  t.pattern = 'spec/{classes,defines,functions,hosts}/**/*_spec.rb'
end

desc "Check the syntax of the puppet manifests"
# Puppet 2.7.x
# puppet parser validate /tmp/test.pp

# Puppet 2.6.x
# puppet --parseonly --ignoreimport /tmp/test.pp
task :check_syntax do
  manifests   = Dir['**/*.pp', '**/*.pp.*'].reject { |path| !!(path =~ /.erb$/) }
  progressbar = ProgressBar.new('Syntax Check', manifests.count)

  manifests.each do |manifest|
    command = "puppet --parseonly --ignoreimport #{ manifest }"
    message = `#{ command }`

    fail message + retest_message(command) unless $?.to_i.zero?
    progressbar.inc
  end

  progressbar.finish
end

desc "Run all CI tasks (:check_syntax, :lint, :spec)"
task :ci => [:check_syntax, :lint, :spec]

private

def retest_message(command)
  "\nRe-run this test with the following command...\nbundle exec #{command}"
end

