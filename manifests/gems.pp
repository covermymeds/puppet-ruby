# == Definition: ruby::gems
#
# Installs gems for a specific SCL Ruby version.
# In order to ensure resource uniqueness of gems across multiple
# Ruby versions, this defined type will prefix each gem with the
# name of the Ruby version.
#
# Additionally, in order to permit per-Ruby version differences, this
# defined type will perform a Hiera lookup for a gem definition for the
# specific Ruby version.
#
# Parameters:
# - $ruby: the version of Ruby into which to install this gem
#          defaults to $title of this resource
# - $gems: a hash of hashes of gems
#
# === Examples:
#
# ruby::gems { 'ruby193':
#   gems => { 'bundler' = { 'version' => '1.0.0' },
#             'rails' = { 'version' => '4.0.0' },
#           }
# }
#
# === Authors
#
# Chris Everest <ceverest@covermymeds.com>
# Scott Merrill <smerrill@covermymeds.com>
#
# === Copyright
#
# Copyright 2014 CoverMyMeds, unless otherwise noted
#
define ruby::gems (
  $ruby = $title,
  $gems = undef,
) {

  validate_string( $ruby )
  validate_hash( $gems )

  # we look for a Hiera key named "ruby::gems::${ruby}".
  # for example: ruby::gems::ruby193
  $specific_gems = hiera_hash( "ruby::gems::${ruby}", undef )
  if $specific_gems {
    $combined_gems = merge( $gems, $specific_gems )
  } else {
    $combined_gems = $gems
  }

  $unique_gems = prefix($combined_gems, "${ruby}_")

  # Validate our hash again, to be safe
  validate_hash( $unique_gems )

  $gem_defaults = {
    require => Package["${ruby}-rubygems"],
  }
  create_resources ( ::ruby::gem, $unique_gems, $gem_defaults )
}
