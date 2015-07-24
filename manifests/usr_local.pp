# == Define: ruby::usr_local
#
# This defined type takes an SCL Ruby version and ensures that that Ruby's
# /usr/local/bin directory is included in the PATH as set by the enable script
#
# This works in conjunction with the ruby::gem defined type, which explicitly
# passes "--bindir /opt/rh/<ruby>/root/usr/local/bin" to the gem installation
#
# === Parameters
#
# ruby: the SCL Ruby version to modify.  Defaults to $title
#
# === Examples
#
# ruby::usr_local { 'ruby193': }
#
# === Authors
#
# Scott Merrill <smerrill@covermymeds.com>
#
# === Copyright
#
# Copyright 2014 CoverMyMeds, unless otherwise noted
#
define ruby::usr_local (
  $ruby = $title,
) {

  # we create this variable to ensure that variable interpolation is
  # is not performed on these shell vars. We then append this to the
  # strings below where THIS variable gets interpolated.
  $path = '${PATH:+:${PATH}}' # lint:ignore:single_quote_string_with_variables

  file_line{ "${ruby} /usr/local/bin":
    path  => "/opt/rh/${ruby}/enable",
    line  => "export PATH=/opt/rh/${ruby}/root/usr/bin:/opt/rh/${ruby}/root/usr/local/bin${path}",
    match => '^export PATH=.+'
  }

}
