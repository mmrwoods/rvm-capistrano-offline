# rvm-capistrano-offline

https://github.com/thickpaddy/rvm-capistrano-offline

## Description

Allows you to use rvm-capistrano behind a bastard firewall that allows no
outbound traffic from your servers.

Can also be used to install rvm and rubies completely offline, hence the name
(rvm-capistrano-behind-a-bastard-firewall was too long)

Works by packaging rvm and ruby source archives, uploading them to servers,
installing rvm from uploaded source and then configuring it to download
rubies from localhost via sftp.

If you think this sounds fscked up, you'd be right, but amazingly it actually
works quite well.

## Caveats

* Experimental, it will break, and it might be a really bad idea anyway
* Only works with MRI Ruby 1.9 at the moment
* Pack task currently updates your local rvm installation (this is bad)
* Requires `rvm_install_type` set to head, stable or master
* Probably fails if `rvm_ruby_string` set to head, default or local
* Only tested with cap multistage, should work without, but don't count on it
* No support for packaging and installing gems (yet)

## Installation

Assuming the **rvm-capistrano** gem is aleady in your `Gemfile`, add
**rvm-capistrano-offline**:

    $ echo "gem 'rvm-capistrano-offline', :git => 'git://github.com/thickpaddy/rvm-capistrano-offline.git'" >> Gemfile
    $ bundle install

And require from your Capistrano recipes:

    require "rvm/capistrano/offline"

## Usage

Package rvm and ruby:

    $ cap rvm_offline:pack

Upload rvm and ruby archives to servers:

    $ cap rvm_offline:upload

Install rvm from uploaded source archive:

    $ cap rvm_offline:install

Configure rvm, curl and ssh/sftp to obtain rubies from localhost:

    $ cap rvm_offline:configure

And now you can install ruby using the standard `rvm:install_ruby` task.
If you change your ruby version, you'll need to pack and upload again.
