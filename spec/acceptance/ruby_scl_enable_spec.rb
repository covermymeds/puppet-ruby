require 'spec_helper_acceptance'

PUPPET_RUN_UNCHANGED = 0
PUPPET_RUN_FAILED    = 1
PUPPET_RUN_CHANGED   = 2

describe 'ruby::gems::bundler class' do
  let(:manifest) {
    <<-EOS
      package { ['yum-utils', 'scl-utils', 'scl-utils-build', 'centos-release-scl']:
        ensure => present;
      }

      class { 'ruby':
        rubies => [ 'ruby200', 'rh-ruby22', ],
      }
    EOS
  }

  it 'should run without errors' do
    result = apply_manifest(manifest, :catch_failures => true)
    expect(@result.exit_code).to eq PUPPET_RUN_CHANGED
  end

  it 'should run again without errors' do
    result = apply_manifest(manifest, :catch_failures => true)
    expect(@result.exit_code).to eq PUPPET_RUN_UNCHANGED
  end

  it 'should install gems to the appropriate scl' do
    manifest = <<-EOS
package { ['yum-utils', 'scl-utils', 'scl-utils-build', 'centos-release-scl']:
  ensure => present;
}

class { 'ruby':
  rubies => [ 'ruby200', 'rh-ruby22', ],
}

ruby::gems { 'ruby200':
  gems => {
    'bundler'  => { 'version' => '1.13.1' },
    'nokogiri' => { 'version' => '1.6.8' },
  },
}
    EOS

    result = apply_manifest(manifest, :catch_failures => true)
    expect(@result.exit_code).to eq PUPET_RUN_CHANGED
  end
end
