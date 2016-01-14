#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
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

require File.expand_path('../rundeck_project', __FILE__)

class Chef
  class Resource::RundeckNodeSource < Resource
    include Poise(RundeckProject)
    actions(:enable, :disable)

    attribute('', template: true)
  end

  class Provider::RundeckNodeSource < Provider
    include Poise

    def action_enable
    end
  end

  # type = file
  class Resource::RundeckNodeSourceFile < Resource::RundeckNodeSource
    attribute('', template: true, default_source: 'source_file.properties.erb')
    attribute(:resources_xml, template: true, default_source: 'resources.xml.erb')
    attribute(:query, kind_of: String, default: lazy { "chef_environment:#{node.chef_environment}" })
    attribute(:limit, kind_of: Integer)
    attribute(:username, kind_of: String, default: lazy { parent.parent.ssh_user })
    attribute(:manual_nodes, kind_of: Array, default: [])

    provides(:rundeck_node_source_file)

    def path
      ::File.join(parent.project_path, 'etc', 'resources.xml')
    end

    def nodes
      if !manual_nodes.empty?
        nodes = manual_nodes
      elsif !node['rundeck']['nodes'].empty?
        nodes = node['rundeck']['nodes']
      elsif Chef::Config[:solo]
        nodes = [{
          'name' => node.name,
          'description' => node['description'],
          'roles' => node['roles'],
          'recipes' => node['recipes'],
          'fqdn' => node['fqdn'],
          'os' => node['os'],
          'kernel_machine' => node['kernel']['machine'],
          'kernel_name' => node['kernel']['name'],
          'kernel_release' => node['kernel']['release'],
        }]
      else
        nodes = partial_search(:node, query, keys: {
          name: %w{name},
          description: %w{description},
          roles: %w{roles},
          recipes: %w{recipes},
          fqdn: %w{fqdn},
          os: %w{os},
          kernel_machine: %w{kernel machine},
          kernel_name: %w{kernel name},
          kernel_release: %w{kernel release},
        })
      end
      nodes = nodes.take(limit) if limit
      nodes
    end
  end

  class Provider::RundeckNodeSourceFile < Provider::RundeckNodeSource
    provides(:rundeck_node_source_file)

    def action_enable
      converge_by("write resources.xml for Rundeck project #{new_resource.parent.project_name}") do
        notifying_block do
          write_resources_xml
        end
      end
    end

    def action_disable
      converge_by("delete resources.xml for Rundeck project #{new_resource.parent.project_name}") do
        notifying_block do
          delete_resources_xml
        end
      end
    end

    private

    def write_resources_xml
      file new_resource.path do
        owner new_resource.parent.parent.user
        group new_resource.parent.parent.group
        mode '600'
        content new_resource.resources_xml_content
      end
    end

    def delete_resources_xml
      r = write_resources_xml
      r.action(:delete)
      r
    end
  end
end
