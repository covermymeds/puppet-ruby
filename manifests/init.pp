# == Class: ruby
#
# Installs one or more Rubies from Software Collections, and an
# optional list of gems
#
# The default Ruby will be enabled system-wide.
#
# Parameters:
# - $rubies: an array of Rubies to install.
# - $devel: whether to install the -devel packages for each Ruby
# - $bash: whether to symlink the default Ruby's enable script
#           into /etc/profile.d, making it available to bash users
#
# The values of the $rubies array elements should be the name of the
# corresponing Software Collection. For example, 'ruby193', 'ruby200'
#
# === Examples:
#
# class { ruby:
#   rubies => [ 'ruby193', 'ruby200' ],
# }
#
# === Authors
#
# Scott Merrill <smerrill@covermymeds.com>
#
# === Copyright
#
# Copyright 2013 CoverMyMeds, unless otherwise noted
#
class ruby (
  $rubies = [],
  $devel  = true,
  $bash  = true,
) {

  validate_array( $rubies )

  # the first Ruby in the array is deemed to be the "default" Ruby
  # this is useful for (and used by) Passenger Enterprise
  $default_ruby = $rubies[0]

  # SCL Ruby packages are of the form ruby123-ruby
  $rubies_packages = suffix( $rubies, '-ruby' )

  package { $rubies_packages:
    ensure => present,
  }

  # the -rubygems RPM should have been installed from the above,
  # but we explicitly call it out here so that we can require it
  # later for gem installation
  $rubies_rubygems = suffix( $rubies, '-rubygems' )
  package { $rubies_rubygems:
    ensure => present,
  }

  if $devel {
    $rubies_devel = suffix ( $rubies, '-ruby-devel' )
    package { $rubies_devel:
      ensure => present,
    }
  }

  # we need to edit each SCL Ruby's enable script to ensure that
  # /opt/rh/<ruby>/root/usr/local/bin is added to the path.
  # We'll use a defined type so we can pass an array of Rubies
  # in one shot
  ruby::usr_local { $rubies: }

  # enable the default Ruby in all users' bash environments
  if $bash {
    file { '/etc/profile.d/scl-ruby.sh':
      ensure  => link,
      target  => "/opt/rh/${default_ruby}/enable",
      require => Package["${default_ruby}-ruby"],
    }
  }

  # get the default set of system gems
  $gems = hiera_hash('ruby::gems', undef)

  # since $rubies is an array, we can pass the whole thing to
  # ::ruby::gems, and it'll trigger for each one.  Thus we
  # can pass the list of system gems for each Ruby
  if $gems {
    validate_hash( $gems )
    ::ruby::gems { $rubies:
      gems => $gems,
    }
  }

}
