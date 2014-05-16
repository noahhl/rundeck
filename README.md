Rundeck Cookbook
================

This is a Chef cookbook to install [Rundeck](http://rundeck.org/), an
orchestration and administration tool.

Quick Start
-----------

The fastest way to get started is to customize the `rundeck.cli_password`,
`rundeck.admin_password`, and `rundeck.ssh_key` node attributes and add
`recipe[rundeck]` to you node's run list. Unfortunately this has some security
issues due to the nature of storing passwords in node attributes. A better
options overall is to create a wrapper cookbook. In your wrapper's `metadata.rb`
add:

```ruby
depends 'rundeck'
```

And then in your wrapper recipe:

```ruby
rundeck node['rundeck']['node_name'] do
  # Get these from somewhere secure like chef-vault or citadel.
  cli_password 'password'
  ssh_key '-----BEGIN RSA PRIVATE KEY-----...'
end

rundeck_user 'myuser' do
  password 'admin' # As above, should come from somewhere secure.
  roles %w{admin user}
end
```

To setup a simple project and job:

```ruby
rundeck_project 'myproj'

rundeck_node_source_file 'myproj'

rundeck_job 'myjob' do
  source 'myjob.yml.erb'
end
```

And then add a YAML template containing your job information. See [the Rundeck
documentation](http://rundeck.org/docs/man5/job-yaml.html) for more information
about the required data and format.

Requirements
------------

### Cookbooks

The following cookbooks are required:

* apt
* java
* poise
* runit
* yum

In order to install the NGINX proxy site, you'll either need the `openresty` or
`nginx` cookbook.

### OS

The following platforms are supported and tested:

* Ubuntu 12.04
* CentOS 6.5

### Chef

This cookbook requires Chef 11 or higher.

Attributes
----------

* `node['rundeck']['version']` – Version of Rundeck to install. *(default: latest)*
* `node['rundeck']['launcher_url']` – Download URL if using the JAR launcher installation method. *(default: https://s3.amazonaws.com/download.rundeck.org/jar/rundeck-launcher-%{version}.jar)*
* `node['rundeck']['path']` – Base path for Rundeck data. *(default: /var/lib/rundeck)*
* `node['rundeck']['config_path']` – Path for Rundeck configuration. *(default: /etc/rundeck)*
* `node['rundeck']['log_path']` – Path for Rundeck log files. *(default: /var/log/rundeck)*
* `node['rundeck']['user']` – User to run Rundeck as. *(default: rundeck)*
* `node['rundeck']['group']` – Group to run Rundeck as. *(default: rundeck)*
* `node['rundeck']['jvm_options']` – Extra options to pass to the JVM.
* `node['rundeck']['node_name']` – Name for the initial Rundeck node. *(default: node.name)*
* `node['rundeck']['port']` – HTTP port for Rundeck. *(default: 4440)*
* `node['rundeck']['public_rss']` – Enable unauthenticated access to RSS feeds. *(default: false)*
* `node['rundeck']['logging_level']` – Default logging level for jobs. *(default: INFO)*
* `node['rundeck']['ssh_user']` – Username Rundeck will SSH to remote servers as. *(default: rundeck)*

### Email settings

* `node['rundeck']['email']['hostname']` – SMTP hostname. *(default: localhost)*
* `node['rundeck']['email']['port']` – SMTP port. *(default: 25)*
* `node['rundeck']['email']['username']` – SMTP username.
* `node['rundeck']['email']['password']` – SMTP password.

### Proxy settings

These settings are used to customize how Rundeck generates links. This is useful
both if you have a DNS name for your Rundeck server and if you are using some
kind of reverse proxy server.

* `node['rundeck']['external_hostname']` – Hostname to use when creating links. *(default: localhost)*
* `node['rundeck']['external_port']` – Port to use when creating links. *(default: node['rundeck']['port'])*
* `node['rundeck']['external_scheme']` – Scheme to use when creating links. Set to HTTPS if you are using a TLS proxy. *(default: http)*

### Insecure settings

Three attributes are provided to set passwords/keys for the default recipe. As
mentioned above, using these can be insecure with chef-server as all node
attributes are visible to all nodes and users in Chef. It is highly recommended
you do not use these, as a wrapper cookbook with a better secrets store is much
safer:

* `node['rundeck']['cli_password']` – CLI user password. *(default: password)*
* `node['rundeck']['admin_password']` – Default admin user password.
* `node['rundeck']['ssh_key']` – SSH private key.


Resources
---------

### rundeck

The `rundeck` resource installs and configures a Rundeck server.

```ruby
rundeck 'name' do
  version '2.1.1'
  port 8080
  cli_password 'password'
  ssh_key '-----BEGIN RSA PRIVATE KEY-----...'
end
```

* `node_name` – Name of the Rundeck server node. *(name_attribute)*
* `version` – Version of Rundeck to install. *(default: node['rundeck']['version'])*
* `launcher_url` – Download URL if using the JAR launcher installation method. *(default: node['rundeck']['launcher_url'])*
* `service_name` – Runit service name. Must be unique on the system. *(default: rundeck)*

* `path` – Base path for Rundeck data. *(default: node['rundeck']['path'])*
* `config_path` – Path for Rundeck configuration. *(default: node['rundeck']['config_path'])*
* `log_path` – Path for Rundeck log files. *(default: node['rundeck']['log_path'])*

* `log4j_config` – Template for log4j.properties. *(template, default_source: log4j.properties.erb)*
* `jaas_config` – Template for jaas-loginmodule.conf. *(template, default_source: jaas-loginmodule.conf.erb)*
* `profile_config` – Template for bash profile config. *(template, default_source: profile.erb)*
* `framework_config` – Template for framework.properties. *(template, default_source: framework.properties.erb)*
* `rundeck_config` – Template for rundeck-config.properties. *(template, default_source: rundeck-config.properties.erb)*
* `realm_config` – Template for realm.properties. *(template, default_source: realm.properties.erb)*
* `enable_default_acls` – Enable default ACLs for admin and cli groups. *(default: true)*

* `user` – User to run Rundeck as. *(default: node['rundeck']['user'])*
* `group` – Group to run Rundeck as. *(default: node['rundeck']['group'])*
* `jvm_options` – Extra options to pass to the JVM. *(default: node['rundeck']['jvm_options'])*
* `port` – HTTP port for Rundeck. *(default: node['rundeck']['port'])*
* `public_rss` – Enable unauthenticated access to RSS feeds. *(default: node['rundeck']['public_rss'])*
* `logging_level` – Default logging level for jobs. *(default: node['rundeck']['logging_level'])*
* `external_host` – Hostname to use when creating links. *(default: node['rundeck']['external_host'])*
* `external_port` – Port to use when creating links. *(default: node['rundeck']['external_port'])*
* `external_scheme` – Scheme to use when creating links. Set to HTTPS if you are using a TLS proxy. *(default: node['rundeck']['external_scheme'])*
* `email` – Email settings. *(option_collector, default: node['rundeck']['email'])*

* `cli_user` – Username for Rundeck CLI tools. *(default: cli)*
* `cli_password` – Password for Rundeck CLI tools. *(required, unless cli_user is false)*
* `create_cli_user` – Create Rundeck user for CLI tools. *(default: true)*

* `ssh_user` – Username Rundeck will SSH to remote servers as. *(default: node['rundeck']['ssh_user'])*
* `ssh_key` – SSH key Rundeck will SSH to remote servers with.

#### Providers

The overall default `Chef::Provider::Rundeck` installs Rundeck using the JAR launcher.
This should work on any platform where Java is supported. If you are on a
Debian-family OS, the default provider is `Chef::Provider::Rundeck::Apt`, which
installs from the official apt repository. If you are on a RHEL-family OS, the
default provider is `Chef::Provider::Rundeck:Yum`, which installs from the
official yum repository.

License
-------

Copyright 2013-2014, Panagiotis Papadomitsos
Copyright 2014, Balanced, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
