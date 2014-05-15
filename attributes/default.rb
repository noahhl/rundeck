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
default['rundeck']['node_name'] = node.name
default['rundeck']['port'] = 4440
default['rundeck']['public_rss'] = false
default['rundeck']['logging_level'] = 'INFO' # Is this useful? It is required to be set in imported jobs.
default['rundeck']['hostname'] = 'localhost'

# Nodes data
default['rundeck']['nodes'] = []

# DANGER, DANGER WILL ROBINSON
# USE OF THESE ATTRIBUTES IS INSECURE
# REALLY DON'T USE THEM
default['rundeck']['cli_password'] = 'password'
default['rundeck']['admin_password'] = nil
# /DANGER ZONE

# Email settings
default['rundeck']['email']['hostname'] = 'localhost'
default['rundeck']['email']['port'] = 25
default['rundeck']['email']['username'] = nil
default['rundeck']['email']['password'] = nil
default['rundeck']['email']['from'] = 'undeck@example.com'
default['rundeck']['email']['tls'] = false

# Proxy settings
default['rundeck']['proxy']['hostname'] = 'localhost'
default['rundeck']['proxy']['port'] = 4440
default['rundeck']['proxy']['scheme'] = 'http'
