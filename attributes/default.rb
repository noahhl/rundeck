#
# Author:: Panagiotis Papadomitsos <pj@ezgr.net>
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013-2014, Panagiotis Papadomitsos
# Copyright 2014, Noah Kantrowitz
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

default['rundeck']['version'] = nil # Use latest by default
default['rundeck']['launcher_url'] = 'https://s3.amazonaws.com/download.rundeck.org/jar/rundeck-launcher-%{version}.jar'
default['rundeck']['path'] = '/var/lib/rundeck'
default['rundeck']['config_path'] = '/etc/rundeck'
default['rundeck']['log_path'] = '/var/log/rundeck'
default['rundeck']['user'] = 'rundeck'
default['rundeck']['group'] = 'rundeck'
default['rundeck']['jvm_options'] = ''

# Framework configuration
default['rundeck']['node_name']     = node.name
default['rundeck']['port']          = 4440
default['rundeck']['log4j_port']    = 4435
default['rundeck']['public_rss']    = false
default['rundeck']['logging_level'] = 'INFO'
default['rundeck']['hostname']      = 'localhost'

default['rundeck']['nodes'] = []

# DANGER, DANGER WILL ROBINSON
# USE OF THESE ATTRIBUTES IS INSECURE
# REALLY DON'T USE THEM
default['rundeck']['cli_password'] = 'password'
default['rundeck']['admin_password'] = nil
# /DANGER ZONE


# Mail data bag
default['rundeck']['mail'] = {
  'hostname'    => 'localhost',
  'port'        => 25,
  'username'    => nil,
  'password'    => nil,
  'from'        => 'ops@example.com',
  'tls'         => false
}
default['rundeck']['mail']['recipients_data_bag'] = 'users'
default['rundeck']['mail']['recipients_query']    = 'notify:true'
default['rundeck']['mail']['recipients_field']    = "['email']"

default['rundeck']['proxy']['hostname'] = 'localhost'
default['rundeck']['proxy']['port'] = 4440
default['rundeck']['proxy']['scheme'] = 'http'
