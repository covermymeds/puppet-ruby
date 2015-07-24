# puppet-scl-ruby
This module installs one or more Ruby versions via [Red Hat Software Collections](https://access.redhat.com/documentation/en-US/Red_Hat_Software_Collections/), as well as an optional list of gems.

The full functionality of this module requires Hiera.

## Rubies
To simply ensure that one or more Ruby versions are installed, use the base `ruby` class with an array of Ruby Software Collections names:

```
  class { ruby: 
    $rubies => [ 'ruby200', 'rh-ruby22', ],
  }
```

The first Ruby in the array will be considered the default Ruby, and will be activated for all bash users.

## Gems
Gems can be installed system-wide on a per-Ruby basis.

```
  ruby::gems { 'ruby193':
    gems => { 'bundler' = { 'version' => '1.0.0' },
              'rails' = { 'version' => '4.0.0' },
            },
  }

  ruby::gems { 'rh-ruby22':
    gems => { 'bundler' = { 'version' => '1.10.6' },
              'rails'   = { 'version' => '4.2.3' },
            },
  }
```

Any Gem executable (binary or script) will be installed into `/opt/rh/<ruby>/root/usr/local/bin`, and that directory will be added to the `PATH` environment variable inside the relevant Software Collection enable script.  This ensures that Gem executables will be available when the Software Collection is enabled. 

The default Gem installation options include `--no-ridoc` and `--no-rdoc`. If you wish to install documentation, you may do so:
```
  ruby::gems { 'rh-ruby22':
    gems => { 'bundler' = { 'version' => '1.10.16',
                            'ridoc'   => true,
                            'rdoc'    => true,
                          },
            },
  }
```

Please note that the `ruby::gems` defined type is a wrapper around the `ruby::gem` defined type. You may use the latter, if you wish, but please consult the code for details.  You're likely better off using `ruby::gems` unless you have very specific needs.

## Hiera
This module is completely compatible with Hiera, and indeed works best with it.

To install multiple Software Collections Rubies from Hiera:
```
  ---
  ruby::rubies:
    - ruby200
    - rh-ruby22
```

The first Ruby in the array will be considered the default Ruby, and will be activated for all bash users.

The base Ruby class performs an explicit `hiera_hash()` lookup for gems to install across all Ruby versions.

One or more gems may be installed for each Ruby version using the `ruby::gems` Hiera hash. The version of each gem to install is mandatory.

    ---
    ruby::gems:
      bundler:
        version: 1.7.3

If you have gems that are only to be installed to a specific SCL Ruby version, you can add another Hiera hash named after the Ruby version:

    ---
    ruby::gems::ruby193:
      rubygems-bundler:
        version: 1.1.0

The above will ensure that the `rubygems-bundler` gem will only be installed to Ruby 1.9.3, regardless of what other Rubies are installed.

The default for SCL gems is to pass `--no-ridoc` and `--no-rdoc` to the installation command.  If you would like to install documentation, add the appropriate boolean to the gem hash entry:

    ---
    ruby::gems:
      bundler:
        version: 1.7.3
        ridoc: true
        rdoc: true

# Contributing
Pull requests are warmly welcomed!

# Copyright

Copyright 2015 [CoverMyMeds](https://www.covermymeds.com/) and released under the terms of the [MIT License](http://opensource.org/licenses/MIT).
