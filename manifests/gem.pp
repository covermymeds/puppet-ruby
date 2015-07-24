# == Define: ruby::gem
#
# This defined type installs a gem into a specific SCL version of Ruby.
# Note that the name of this resource is expected to be in the form
# "rubyver_gem", so that we can install multiple gems into multiple
# Software Collections Rubies.
#
# === Parameters
#
# version: the version to install. Mandatory.
# options: installation options.
#
# === Examples
#
# === Authors
#
# Scott Merrill <smerrill@covermymeds.com>
#
# === Copyright
#
# Copyright 2014, CoverMyMeds unless otherwise noted
#
define ruby::gem (
  $version,
  $ri      = false,
  $rdoc    = false,
  $options = undef,
) {

  if $ri {
    $_ri = '--ri'
  } else {
    $_ri = '--no-ri'
  }

  if $rdoc {
    $_rdoc = '--rdoc'
  } else {
    $_rdoc = '--no-rdoc'
  }

  # the $name value of this defined type is expected to come through
  # with the SCL Ruby version prefixed to the gem name. We'll need to split it.
  $gemdata = split($name, '_')
  $ruby = $gemdata[0]
  $gem = regsubst($name, "^${ruby}_(.+)", '\1')
  if empty($gem) {
    fail('The gem name could not be distinguished from the ruby version')
  }

  $_v = "--version ${version}"

  $default_options = "${_ri} ${_rdoc} --bindir /opt/rh/${ruby}/root/usr/local/bin"
  # we have a specific set of options required, but additional options
  # can be specified
  if $options {
    $_o = join( [$default_options, $options], ' ' )
  } else {
    $_o = $default_options
  }

  exec { "install gem ${gem} for ${ruby}":
    command => "/usr/bin/scl enable ${ruby} 'gem install ${gem} ${_v} ${_o}'",
    unless  => "/usr/bin/scl enable ${ruby} 'gem list -i -l ${_v} ${gem}'",
  }
}
