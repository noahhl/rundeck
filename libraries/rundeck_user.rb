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
  class Resource::RundeckUser < Resource
    include Poise(Rundeck)
    actions(:enable)

    attribute(:username, kind_of: String, default: lazy { name.split('::').last })
    attribute(:password, kind_of: String, required: true)
    attribute(:format, equal_to: %w{crypt md5 plain}, default: 'md5')
    attribute(:roles, kind_of: Array, default: [])

    def formatted_password
      # Allow pre-obfuscated passwords
      return password if password.start_with?('CRYPT:') || password.start_with?('MD5:')
      case format
      when 'crypt'
        'CRYPT:' + password.crypt('rb')
      when 'md5'
        require 'digest/md5'
        'MD5:' + Digest::MD5.hexdigest(password)
      when 'plain'
        password
      end
    end

    def after_created
      super
      notifies(:rebuild_realm, parent)
    end
  end

  class Provider::RundeckUser < Provider
    include Poise

    def action_enable
      # This space left intentionally blank
    end
  end
end
