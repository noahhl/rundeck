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

rundeck_project 'teapot'

rundeck_node_source_file 'teapot'

rundeck_job 'short' do
  source 'job-one.yml.erb'
  options(
    :description => 'Utah teapot',
    :command => 'echo Newell teapot'
  )
end

rundeck_project 'cron'

rundeck_node_source_file 'cron'

# Wipe at the start to ensure https://github.com/rundeck/rundeck/issues/773 is caught
%w{crontab cron-verbose}.each do |name|
  execute "rd-jobs purge -p cron -n #{name}" do
    environment 'RDECK_BASE' => '/var/lib/rundeck'
  end
end

rundeck_job 'crontab' do
  source 'job-crontab.yml.erb'
end

rundeck_job 'cron-verbose' do
  source 'job-cron-verbose.yml.erb'
end
