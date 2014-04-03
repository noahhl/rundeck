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

require File.expand_path('../rundeck', __FILE__)

class Chef
  class Resource::RundeckProject < Resource
    include Poise(parent: Rundeck, container: true)
    actions(:enable, :disable, :reconfigure)

    attribute(:project_name, kind_of: String, default: lazy { name.split('::').last }) # This should validate for bad chars
    attribute('', template: true, default_source: 'project.properties.erb')
    attribute(:ssh_authentication, equal_to: %{privateKey password}, default: 'privateKey')
    attribute(:ssh_key, kind_of: String, default: lazy { ::File.join(parent.path, '.ssh', 'id_rsa') })
    attribute(:executor, equal_to: %{jsch-ssh stub}, default: 'jsch-ssh') # script-exec/copy not supported yet
    attribute(:file_copier, equal_to: %{jsch-scp stub}, default: 'jsch-scp')

    def project_path
      ::File.join(parent.path, 'projects', project_name)
    end
  end

  class Provider::RundeckProject < Provider
    include Poise

    def action_enable
      converge_by("create Rundeck project #{new_resource.project_name}") do
        notifying_block do
          create_project_dir
          create_project_etc_dir
          write_project_config
        end
      end
    end

    def action_disable
      converge_by("remove Rundeck project #{new_resource.project_name}") do
        notifying_block do
          delete_project_dir
        end
      end
    end

    def action_reconfigure
      converge_by("update Rundeck project #{new_resource.project_name}") do
        notifying_block do
          write_project_config
        end
      end
    end


    private

    def create_project_dir
      directory new_resource.project_path do
        owner new_resource.parent.user
        group new_resource.parent.group
        mode '700'
      end
    end

    def create_project_etc_dir
      directory ::File.join(new_resource.project_path, 'etc') do
        owner new_resource.parent.user
        group new_resource.parent.group
        mode '700'
      end
    end

    def write_project_config
      file ::File.join(new_resource.project_path, 'etc', 'project.properties') do
        owner new_resource.parent.user
        group new_resource.parent.group
        mode '600'
        content new_resource.content
      end
    end

    def delete_project_dir
      r = create_project_dir
      r.action(:delete)
      r
    end
  end
end
