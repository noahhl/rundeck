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

require File.expand_path('../rundeck', __FILE__)

class Chef
  class Resource::RundeckAcl < Resource
    include Poise(Rundeck)
    actions(:enable, :disable)

    attribute(:acl_name, kind_of: String, default: lazy { name.split('::').last })
    attribute('', template: true, required: true)
  end

  class Provider::RundeckAcl < Provider
    include Poise

    def action_enable
      converge_by("enable ACL policy #{new_resource.acl_name}") do
        notifying_block do
          write_acl
        end
      end
    end

    def action_disable
      converge_by("disable ACL policy #{new_resource.acl_name}") do
        notifying_block do
          delete_acl
        end
      end
    end

    private

    def write_acl
      file ::File.join(new_resource.parent.config_path, "#{new_resource.acl_name}.aclpolicy") do
        owner new_resource.parent.user
        group new_resource.parent.group
        mode '600'
        content new_resource.content
      end
    end

    def delete_acl
      r = write_acl
      r.action(:delete)
      r
    end
  end
end
