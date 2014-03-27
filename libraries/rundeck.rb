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
    actions(:install)

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
    attribute(:enable_default_acls, equal_to: [true, false], default: true)
    # Config options
    attribute(:user, kind_of: String, default: lazy { node['rundeck']['user'] })
    attribute(:group, kind_of: String, default: lazy { node['rundeck']['group'] })
    attribute(:port, kind_of: [String, Integer], default: lazy { node['rundeck']['port'] })
    attribute(:log4j_port, kind_of: [String, Integer], default: lazy { node['rundeck']['log4j_port'] })
    attribute(:public_rss, equal_to: [true, false], default: lazy { node['rundeck']['public_rss'] })
    attribute(:logging_level, kind_of: String, default: lazy { node['rundeck']['logging_level'] })

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

    def action_install
      converge_by("install a rundeck server") do
        notifying_block do
          create_group
          create_user
          create_directories
          install_java
          install_rundeck
          write_configs
          configure_service
        end
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

    def write_configs
      write_log4j_config
      write_jaas_config
      write_profile_config
      write_framework_config
      write_rundeck_config
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

    def configure_service
      include_recipe 'runit'

      runit_service new_resource.service_name do
        cookbook 'rundeck'
        run_template_name 'rundeck'
        log_template_name 'rundeck'
        options new_resource: new_resource
      end
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
