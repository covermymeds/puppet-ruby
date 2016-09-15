require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'

require 'pry'

run_puppet_install_helper
install_module_on(hosts)
install_module_dependencies_on(hosts)

RSpec.configure do |c|

  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  c.before :suite do
    hosts.each do |host|
      puppet_module_install(source: module_root, module_name: 'ruby')
      on(host, puppet('module', 'install', 'puppetlabs-stdlib'))

     #manifest = <<-EOS
     #package { ['yum-utils', 'scl-utils', 'scl-utils-build', 'centos-release-scl']:
     #  ensure => present;
     #}
     #EOS
     #apply_manifest(manifest, catch_failures: false)
    end
  end
end
