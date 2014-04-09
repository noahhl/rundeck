#
# Author:: Panagiotis Papadomitsos (<pj@ezgr.net>)
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013-2014, Panagiotis Papadomitsos
# Copyright 2014, Balanced, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  class Resource::Rundeck < Resource
    include Poise(container: true)
    actions(:install, :restart, :rebuild_realm, :wait_until_up)

    attribute(:node_name, kind_of: String, name_attribute: true)
    attribute(:version, kind_of: String, default: lazy { node['rundeck']['version'] })
    attribute(:launcher_url, kind_of: String, default: lazy { node['rundeck']['launcher_url'] })
    attribute(:service_name, kind_of: String, default: 'rundeck')
    # Paths
    attribute(:path, kind_of: String, default: lazy { node['rundeck']['path'] })
    attribute(:config_path, kind_of: String, default: lazy { node['rundeck']['config_path'] })
    attribute(:log_path, kind_of: String, default: lazy { node['rundeck']['log_path'] })
    # Configuration templates
    attribute(:log4j_config, template: true, default_source: 'log4j.properties.erb')
    attribute(:jaas_config, template: true, default_source: 'jaas-loginmodule.conf.erb')
    attribute(:profile_config, template: true, default_source: 'profile.erb')
    attribute(:framework_config, template: true, default_source: 'framework.properties.erb')
    attribute(:rundeck_config, template: true, default_source: 'rundeck-config.properties.erb')
    attribute(:realm_config, template: true, default_source: 'realm.properties.erb')
    attribute(:enable_default_acls, equal_to: [true, false], default: true)
    # Config options
    attribute(:user, kind_of: String, default: lazy { node['rundeck']['user'] })
    attribute(:group, kind_of: String, default: lazy { node['rundeck']['group'] })
    attribute(:jvm_options, kind_of: String, default: lazy { node['rundeck']['jvm_options'] })
    attribute(:port, kind_of: [String, Integer], default: lazy { node['rundeck']['port'] })
    attribute(:log4j_port, kind_of: [String, Integer], default: lazy { node['rundeck']['log4j_port'] })
    attribute(:public_rss, equal_to: [true, false], default: lazy { node['rundeck']['public_rss'] })
    attribute(:logging_level, kind_of: String, default: lazy { node['rundeck']['logging_level'] })
    attribute(:hostname, kind_of: String, default: lazy { node['rundeck']['hostname'] })
    # CLI usage
    attribute(:cli_user, kind_of: [String, FalseClass], default: 'cli')
    attribute(:cli_password, kind_of: String, required: true)
    attribute(:create_cli_user, equal_to: [true, false], default: true)
    # SSH Options
    attribute(:ssh_user, kind_of: String, default: 'rundeck')
    attribute(:ssh_key, kind_of: String)

    def after_created
      super
      # Interpolate the version into the launcher download URL
      launcher_url(launcher_url % {version: version})
    end

    def provider_for_action(*args)
      unless provider
        if node.platform_family?('debian')
          provider(Provider::Rundeck::Apt)
        elsif node.platform_family?('rhel') # Fedora?
          provider(Provider::Rundeck::Yum)
        end
      end
      super
    end
  end

  class Provider::Rundeck < Provider
    include Poise
    include Mixin::ShellOut

    def action_install
      converge_by("install a rundeck server") do
        notifying_block do
          create_group
          create_user
          create_directories
          install_java
          install_rundeck
          create_cli_user if new_resource.create_cli_user
          write_configs
          write_ssh_key if new_resource.ssh_key
          configure_service
        end
      end
    end

    def action_restart
      service_resource.run_action(:restart)
      action_wait_until_up
    end

    def action_rebuild_realm
      converge_by("install a rundeck server") do
        notifying_block do
          write_realm_config
        end
      end
    end

    def action_wait_until_up
      Chef::Log.info "Waiting until Rundeck is listening on port #{new_resource.port}"
      until service_listening?
        sleep 1
        Chef::Log.debug('.')
      end

      Chef::Log.info 'Waiting until the Jenkins API is responding'
      until endpoint_responding?
        sleep 1
        Chef::Log.debug('.')
      end
    end

    private

    def create_group
      group new_resource.group do
        system true
      end
    end

    def create_user
      user new_resource.user do
        comment "Rundeck service user for #{new_resource.path}"
        gid new_resource.group
        system true
        shell '/bin/false'
        home new_resource.path
      end
    end

    def create_directories
      [
        [new_resource.path],
        [new_resource.config_path],
        [new_resource.log_path],
        [new_resource.path, 'projects'],
        [new_resource.path, 'var'],
        [new_resource.path, 'var', 'tmp'],
        [new_resource.path, 'libext'],
        [new_resource.path, 'data'],
        [new_resource.path, '.ssh'],
      ].each do |path|
        directory ::File.join(*path) do
          owner new_resource.user
          group new_resource.group
          mode '700'
        end
      end
    end

    def install_java
      include_recipe 'java'
    end

    def install_rundeck
      raise NotImplementedError, "Jar launcher install not written"
    end

    def create_cli_user
      rundeck_user new_resource.cli_user do
        parent new_resource
        password new_resource.cli_password
        roles %w{admin cli}
      end
    end

    def write_configs
      write_log4j_config
      write_jaas_config
      write_profile_config
      write_framework_config
      write_rundeck_config
      write_realm_config
      write_default_acls if new_resource.enable_default_acls
    end

    def write_log4j_config
      file ::File.join(new_resource.config_path, 'log4j.properties') do
        owner new_resource.user
        group new_resource.group
        mode '600'
        content new_resource.log4j_config_content
        notifies :restart, new_resource
      end
    end

    def write_jaas_config
      file ::File.join(new_resource.config_path, 'jaas-loginmodule.conf') do
        owner new_resource.user
        group new_resource.group
        mode '600'
        content new_resource.jaas_config_content
        notifies :restart, new_resource
      end
    end

    def write_profile_config
      file ::File.join(new_resource.config_path, 'profile') do
        owner new_resource.user
        group new_resource.group
        mode '600'
        content new_resource.profile_config_content
        notifies :restart, new_resource
      end
    end

    def write_framework_config
      file ::File.join(new_resource.config_path, 'framework.properties') do
        owner new_resource.user
        group new_resource.group
        mode '600'
        content new_resource.framework_config_content
        notifies :restart, new_resource
      end
    end

    def write_rundeck_config
      file ::File.join(new_resource.config_path, 'rundeck-config.properties') do
        owner new_resource.user
        group new_resource.group
        mode '600'
        content new_resource.rundeck_config_content
        notifies :restart, new_resource
      end
    end

    def write_realm_config
      file ::File.join(new_resource.config_path, 'realm.properties') do
        owner new_resource.user
        group new_resource.group
        mode '600'
        content new_resource.realm_config_content
      end
    end

    def write_default_acls
      rundeck_acl 'admin' do
        parent new_resource
        source 'admin.aclpolicy.erb'
        cookbook 'rundeck'
      end

      rundeck_acl 'apitoken' do
        parent new_resource
        source 'apitoken.aclpolicy.erb'
        cookbook 'rundeck'
      end
    end

    def write_ssh_key
      file ::File.join(new_resource.path, '.ssh', 'id_rsa') do
        owner new_resource.user
        group new_resource.group
        mode '600'
        content new_resource.ssh_key
      end
    end

    def service_resource
      include_recipe 'runit'

      if !@service_resource
        subcontext_block do
          @service_resource = runit_service new_resource.service_name do
            action :nothing
            cookbook 'rundeck'
            run_template_name 'rundeck'
            log_template_name 'rundeck'
            options new_resource: new_resource
            sv_timeout 60 # It can be slow while the cache is loading
          end
        end
      end
      @service_resource
    end

    def configure_service
      r = service_resource
      ruby_block 'configure_service' do
        block do
          r.run_action(:enable)
          r.run_action(:start)
        end
        # I hate this
        notifies :wait_until_up, new_resource, :immediately
      end
    end

    # Helpers used to check if Rundeck is available
    def service_listening?
      cmd = shell_out!('netstat -lnt')
      cmd.stdout.each_line.select do |l|
        l.split[3] =~ /#{new_resource.port}/
      end.any?
    end

    def endpoint_responding?
      url = "http://localhost:#{new_resource.port}/login"
      response = Chef::REST::RESTRequest.new(:GET, URI.parse(url), nil).call
      if response.kind_of?(Net::HTTPSuccess) ||
            response.kind_of?(Net::HTTPOK) ||
            response.kind_of?(Net::HTTPRedirection) ||
            response.kind_of?(Net::HTTPForbidden)
        Chef::Log.debug("GET to #{url} successful")
        return true
      else
        Chef::Log.debug("GET to #{url} returned #{response.code} / #{response.class}")
        return false
      end
    rescue EOFError, Errno::ECONNREFUSED
      Chef::Log.debug("GET to #{url} failed with connection refused")
      return false
    end
  end

  class Provider::Rundeck::Apt < Provider::Rundeck
    def install_rundeck
      enable_repository
      install_package
      remove_package_service_scripts
    end

    def enable_repository
      apt_repository 'rundeck-bintray' do
        uri 'https://dl.bintray.com/rundeck/rundeck-deb'
        distribution '/'
        trusted true
      end
    end

    def install_package
      package 'rundeck' do
        action :upgrade unless new_resource.version
        version new_resource.version
      end
    end

    def remove_package_service_scripts
      file '/etc/init/rundeckd.conf' do
        action :delete
      end

      file '/etc/init.d/rundeckd' do
        action :delete
      end
    end
  end

  class Provider::Rundeck::Yum < Provider::Rundeck
    def install_rundeck
      enable_repository
      install_package
    end
  end
end
