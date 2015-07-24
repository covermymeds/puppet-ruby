# Definition: ruby::app
#
# This class installs a Ruby application
#
# Parameters:
# - $ruby: the Ruby version to use
# - $allow_from: array of IPs permitted to access this application
# - $custom_options: a string of custom options to apply
# - $passenger_max_instances: the maximum number of Passenger instances permitted
# - $passenger_min_instances: the minimum number of Passenger instances to keep available
# - $passenger_max_request_queue_size: the max number of requests to queue 
#     before sending the client a 503 Error
# - $ssl: boolean of whether to use HTTPS/443, default false
# - $secret_key_base: Rails 4 token used to secure cookies
#
# Actions:
# - Install Ruby application
# - Setup monitoring for the applications, this is handled via a custom fact
#   and then checking if "${app_name}_release is defined.
#
# Requires:
# - Role Passenger module
# - Ruby
#
define ruby::app(
  $ruby = undef,
  $allow_from = [],
  $custom_options = '',
  $passenger_max_instances = 8,
  $passenger_min_instances = undef,
  $passenger_max_request_queue_size = undef,
  $ssl = true,
  $secret_key_base = undef,
  ) {

  if $ruby {
    $passenger_ruby = "/opt/rh/${ruby}/root/usr/bin/ruby"
  }

  validate_array($allow_from)
  # Note: due to a shortcoming in the PuppetLabs Apache module, the array
  # of allow_from addresses is passed to a template, rather than used directly
  # https://github.com/puppetlabs/puppetlabs-apache/issues/556

  $app_name = $name
  $up_appname = upcase(regsubst($app_name, '-', '_', 'G' ))
  $vhost_name = "${app_name}.${::webserver::vhost_domain}"
  $app_dir = "/pub/${app_name}"
  $docroot = "${app_dir}/current/public"

  # production servers should only answer to their specific name.
  # everything else should support wildcard prefixes, like:
  #  - smerrill-atlas.staging.covermymeds.com
  #  - ceverest-ferret.innova.local
  $server_alias = $::app_env ? {
    'production' => [],
    default      => [ "*-${vhost_name}" ],
  }

  # Add the SENTRY_DSN variable
  $sentry_dsn = $::app_env ? {
    'development'  => '',
    default        => getvar("${app_name}_sentry_dsn"),
  }

  # this is a null declaration to ensure that the Apache module
  # doesn't try to helpfully create the docroot.  Our docroots will
  # all be created by app deployments
  if !defined(File[$docroot]) {
    file{ $docroot:
    }
  }

  if ($::app_env != 'development') and (size($allow_from) > 0) {
    $_allow_from = true
  } else {
    $_allow_from = false
  }

  $apache_env_defaults = [
    "APP_ID ${::app_id}",
    "APP_ENV ${::app_env}",
    "${up_appname}_ENV_FILE /etc/cmm/${app_name}.json",
  ]

  if $sentry_dsn {
    $apache_env_sentry = [ "SENTRY_DSN ${sentry_dsn}", ]
  } else {
    $apache_env_sentry = []
  }

  # TODO: Get rid of this it's ugly and not useful anywhere else
  if !empty($::db_cmm) and !empty($::db_central) {
    $apache_env_db = [
      "DB_CMM ${::db_cmm}",
      "DB_CENTRAL ${::db_central}",
    ]
  } else {
    $apache_env_db = []
  }

  if $secret_key_base {
    $apache_env_secret = [ "SECRET_KEY_BASE ${secret_key_base}" ]
  } else {
    $apache_env_secret = []
  }

  # merge all of the available environment arrays into a single one
  $_apache_env = flatten( [ $apache_env_defaults,
                          $apache_env_db,
                          $apache_env_sentry,
                          $apache_env_secret, ]
                        )

  # Setup Plain HTTP vhost params
  $default = {
    port              => '80',
    access_log_file    => "${app_name}.log",
    access_log_env_var => '!monitor',
    access_log_format  => 'combined',
    custom_fragment    => template("${module_name}/ruby_httpd_fragment.erb"),
    docroot            => $docroot,
    error_log_file     => "${app_name}-e.log",
    serveraliases      => $server_alias,
    servername         => $vhost_name,
    setenv             => $_apache_env,
    setenvif           => [ 'User-Agent "^F5\ BIG-IP\ Monitor$" monitor' ],
  }

  if ( $ssl ) {
    # Declare additional HTTPS params
    $add_ssl = {
      port      => '443',
      ssl       => true,
      ssl_ca    => $::ssl::cacert,
      ssl_chain => $::ssl::chainfile,
      ssl_cert  => $::ssl::cert,
      ssl_key   => $::ssl::key,
    }
    # Merge uses the rightmost duplicate hash key
    # Port 443 wins here
    $final_vhost = { "${app_name}" => merge($default, $add_ssl) }
  } else {
    $final_vhost = { "${app_name}" => $default }
  }
  create_resources(apache::vhost, $final_vhost)

  # Provide a custom systemd service file for apache2.4
  if ($::operatingsystemmajrelease > 6)  {
    if $ruby {
      $ruby_ver = $ruby
    } else {
      $ruby_ver = $::ruby::default_ruby
    }
    ensure_resource('file', '/etc/systemd/system/httpd.service', {
      ensure  => file,
      content => template('ruby/httpd.service.erb'),
      notify  => [ Exec['systemctl-daemon-reload'], Service['httpd'] ],
    })
  }
  
  # ensure the application directory exists
  # but allow resource to pre-exist
  if !defined(File[$app_dir]) {
    file { $app_dir:
      ensure => directory,
      owner  => 'deployer',
      group  => 'deployer',
      mode   => '0775',
    }
  }

  # ensure the $app_dir/shared/log directories exists with perms
  file { "${app_dir}/shared" :
    ensure => directory,
    owner  => 'deployer',
    group  => 'deployer',
    mode   => '0775',
  }

  file { "${app_dir}/shared/log" :
    ensure => directory,
    owner  => 'deployer',
    group  => 'apache',
    mode   => '0775',
  }

  # set up log rotation for the app
  logrotate::rule { $app_name:
    ensure       => present,
    path         => ["${app_dir}/shared/log/${::app_env}.log", "${app_dir}/shared/log/newrelic_agent.log"],
    rotate_every => 'week',
    rotate       => 4,
    compress     => true,
    missingok    => true,
    create       => true,
    create_mode  => 0664,
    create_owner => apache,
    create_group => deployer,
    postrotate   => "touch ${app_dir}/current/tmp/restart.txt",
  }

  # set up log rotation for the bluepill
  bluepill::app { $app_name: }

  # Ship logs via beaver
  if $::app_env != 'development' {
    ensure_resource('Beaver::Stanza', 'passenger_log', {
      type    => 'passenger',
      source  => '/var/log/passenger.log',
      tags    => ['passenger', $::app_env],
      require => Class['::central_logging::beaver'],
    })

    # Logstash-formatted logs
    ensure_resource('Beaver::Stanza', 'pub_shared_app_json_logs', {
      format          => 'rawjson',
      source          => "/pub/*/shared/log/logstash*_${::app_env}.log",
      redis_namespace => 'json:beaver',
      type            => 'ruby',
      tags            => [ $::app_env ],
      require         => Class['::central_logging::beaver'],
    })

    # Nominal log format
    ensure_resource('Beaver::Stanza', 'pub_shared_app_logs', {
      type    => 'app_log',
      source  => '/pub/*/shared/log/[!logstash_]*.log',
      tags    => ['app_log', $::app_env],
      require => Class['::central_logging::beaver'],
    })
  }

}
