Rundeck Cookbook
================

This is a Chef cookbook to install [Rundeck](http://rundeck.org/), an
orchestration and administration tool.

Quick Start
-----------

The fastest way to get started is to customize the following node attributes: 
* `rundeck.cli_password`
* `rundeck.admin_password`
* `rundeck.ssh_key` 

 then add the following to your node's run list. 
* `recipe[rundeck]` 

Unfortunately this has some securityissues due to the nature of storing passwords in node attributes (see below). 

A better option is to create a wrapper cookbook. In your wrapper's `metadata.rb`
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

Recipes
-------

### default

The default recipe (`recipe[rundeck]`) installs and configures a Rundeck server
and optionally a single admin user. As noted above, you are highly encouraged
to not use this recipe directly, in favor of making a wrapper cookbook and using
the underlying resources yourself. This is because the recipe is configured
using node attributes, and in a chef-server/client setup this is insecure. If
you are using chef-solo, this recipe is believed to be safe at this time.

To use the recipe, `node['rundeck']['cli_password']` and
`node['rundeck']['ssh_key']` are required. `node['rundeck']['admin_password']`
is optional, if present an admin user named `admin` will be created with the
provided password.

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

#### Core attributes

* `node_name` – Name of the Rundeck server node. *(name_attribute)*
* `version` – Version of Rundeck to install. *(default: node['rundeck']['version'])*
* `launcher_url` – Download URL if using the JAR launcher installation method. *(default: node['rundeck']['launcher_url'])*
* `service_name` – Runit service name. Must be unique on the system. *(default: rundeck)*

##### Path attributes

* `path` – Base path for Rundeck data. *(default: node['rundeck']['path'])*
* `config_path` – Path for Rundeck configuration. *(default: node['rundeck']['config_path'])*
* `log_path` – Path for Rundeck log files. *(default: node['rundeck']['log_path'])*

##### Template attributes

* `log4j_config` – Template for log4j.properties. *(template, default_source: log4j.properties.erb)*
* `jaas_config` – Template for jaas-loginmodule.conf. *(template, default_source: jaas-loginmodule.conf.erb)*
* `profile_config` – Template for bash profile config. *(template, default_source: profile.erb)*
* `framework_config` – Template for framework.properties. *(template, default_source: framework.properties.erb)*
* `rundeck_config` – Template for rundeck-config.properties. *(template, default_source: rundeck-config.properties.erb)*
* `realm_config` – Template for realm.properties. *(template, default_source: realm.properties.erb)*
* `enable_default_acls` – Enable default ACLs for admin and cli groups. *(default: true)*

##### Configuration attributes

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

##### CLI attributes

* `cli_user` – Username for Rundeck CLI tools. *(default: cli)*
* `cli_password` – Password for Rundeck CLI tools. *(required, unless cli_user is false)*
* `create_cli_user` – Create Rundeck user for CLI tools. *(default: true)*

##### SSH attributes

* `ssh_user` – Username Rundeck will SSH to remote servers as. *(default: node['rundeck']['ssh_user'])*
* `ssh_key` – SSH key Rundeck will SSH to remote servers with.

#### Providers

##### Chef::Provider::Rundeck::Apt

If you are on a Debian-family platform, by default Rundeck will be installed
from the official Apt repository.

##### Chef::Provider::Rundeck:Yum

If you are on a RHEL-family platform, by default Rundeck will be installed
from the official Yum repository.

##### Chef::Provider::Rundeck

If you are on neither of the above, Rundeck will be installed using the JAR
launcher. In this case, the `version` attribute is required as there is no
way to determine what version is the latest. You can force either of the above
platforms to install using the JAR launcher by manually setting the provider:

```ruby
rundeck 'name'
  provider :rundeck
  ...
end
```

### rundeck_project

The `rundeck_project` resource creates a Rundeck project. It is a subresource
of `rundeck`.

```ruby
rundeck_project 'name' do
  executor 'stub'
  file_copier 'stub'
end
```

* `project_name` – Name of the project. *(name_attribute)*
* `''` – Project template. *([template](https://github.com/poise/poise#template-content), default_source: project.properties.erb)*
* `ssh_authentication` – SSH authentication mode. One of: `privateKey`, `password`. *(default: privateKey)*
* `ssh_key` – SSH key Rundeck will SSH to remote servers with. *(deafault: parent.path/.ssh/id_rsa)*
* `executor` – Execution mode. One of: `jsch-ssh`, `stub`. *(default: jsch-ssh)*
* `file_copier` – File copier mode. One of: `jsch-scp`, `stub`. *(default: jsch-scp)*

### rundeck_node_source_file

The `rundeck_node_source_file` creates a node catalog file for a Rundeck project.
It is a subresource of `rundeck_project`.

```ruby
rundeck_node_source_file 'name' do
  query 'chef_environment:prod AND tags:enabled'
end
```

* `''` – Source properties template. *([template](https://github.com/poise/poise#template-content), default_source: source_file.properties.erb)*
* `resources_xml` – Node catalog template. *([template](https://github.com/poise/poise#template-content), default_source: resources.xml.erb)*
* `query` – Chef search query to generate node catalog. *(default: chef_environment:node.chef_environment)*
* `ssh_user` – Username Rundeck will SSH to remote servers as. *(default: parent.parent.ssh_user)*

### rundeck_job

The `rundeck_job` resource creates a Rundeck job. It is a subresource of
`rundeck_project`.

```ruby
rundeck_job 'name' do
  source 'job.yml.erb'
end
```

* `job_name` – Name of the job. *(name_attribute)*
* `format` – Job format. One of: `xml`, `yaml`. *(default: yaml)*
* `''` – Job template. *([template](https://github.com/poise/poise#template-content), required)*

**NOTE**: XML format support not currently available.

### rundeck_user

The `rundeck_user` resource creates a Rundeck user. These are used to authenticate
to the Rundeck web interface and API. It is a subresource of `rundeck`.

```ruby
rundeck_user 'name' do
  password 'whatmeworry'
end
```

* `username` – User name. *(name_attribute)*
* `password` – Password data. See below for more information. *(required)*
* `format` – Password format. See below for more information. One of: `md5`, `crypt`, `plain`. *(default: md5)*
* `roles` – Array of roles to add the user to.

Thee modes are available for password obfuscation: unsalted MD5, crypt, and
plain text. If you use `format 'md5'` or `format 'crypt'`, you should pass
`password` in plain text and the resource will obfuscate the password before
writing to the file. The recommended way to handle passwords is to MD5-hash
the password yourself and use the `plain` format like so:

```ruby
rundeck_user 'name' do
  format 'plain'
  password 'MD5:'+hash
end
```

You are highly encouraged to store the hash just like you would a password, as
unsalted MD5 is trivially crackable in most cases. [The citadel cookbook](https://github.com/balanced-cookbooks/citadel)
and [chef-vault](https://github.com/Nordstrom/chef-vault) are both good options
for secure storage. Even with this, do not use the same password as you do for
other websites.

### rundeck_acl

The `rundeck_acl` resource creates an ACL configuration for Rundeck. It is a
subresource of `rundeck`.

```ruby
rundeck_acl 'name' do
  source 'myacl.erb'
end
```

* `acl_name` – ACL name. *(name_attribute)*
* `''` – ACL template. *([template](https://github.com/poise/poise#template-content), required)*

Example
-------

An example of a small wrapper cookbook. All you need is two files, the cookbook
metadata and a recipe.

### metadata.rb

```ruby
name 'mycompany-rundeck'
version '1.0.0'
depends 'rundeck'
depends 'citadel'
```

### recipes/default.rb

```ruby
# Install Rundeck
rundeck node['rundeck']['node_name'] do
  cli_password citadel['rundeck/cli_password']
  ssh_key citadel['deploy_key/deploy.pem']
end

# Create an admin user for ourselves
rundeck_user 'asmithee' do
  format 'plain'
  password 'MD5:'+citadel['rundeck/asmithee_password']
  roles %w{admin user}
end

# Create a project for general purpose jobs
rundeck_project 'mycompany' do
  # Create a node source using all Chef nodes in the same environment
  rundeck_node_source_file 'mycompany'

  # Create two jobs from template files
  rundeck_job 'deploy' do
    source 'deploy.yml.erb'
  end

  rundeck_job 'migrate' do
    source 'migrate.yml.erb'
  end
end
```

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
