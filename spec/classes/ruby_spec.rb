require 'spec_helper'

describe 'ruby', :type => :class do
  context 'valid SCL options' do
    let :params do
      { :rubies => [ 'ruby200' ] }
    end
    it 'should create ruby::scl' do
      should contain_package('ruby200-rubygems')
    end
  end

  context 'install devel package' do
    let :params do
      { :rubies => [ 'ruby200' ], :devel => true }
    end
    it 'should install rubyXYZ-ruby-devel' do
      should contain_package('ruby200-ruby-devel')
    end
  end
  context 'do not install devel package' do
    let :params do
      { :rubies => [ 'ruby200' ], :devel => false }
    end
    it 'should not install rubyXYZ-ruby-devel' do
      should_not contain_package('ruby200-ruby-devel')
    end
  end

  context 'multiple ruby envs enablement with correct order' do
    let :params do
      { :rubies => [ 'rh-ruby22', 'rh-ruby24' ] }
    end
    it { is_expected.to contain_concat__fragment("rh-ruby24").with(
        'source'  => '/opt/rh/rh-ruby24/enable',
        'target'  => '/etc/profile.d/scl-ruby.sh',
       )}
    it { is_expected.to contain_concat__fragment("rh-ruby22").with(
        'source'  => '/opt/rh/rh-ruby22/enable',
        'target'  => '/etc/profile.d/scl-ruby.sh',
       )}
  end
end
