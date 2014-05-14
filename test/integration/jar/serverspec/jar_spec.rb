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

require 'serverspec'
include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

ENV['RDECK_BASE'] = '/var/lib/rundeck'

describe 'Configuration' do
  describe file('/etc/rundeck') do
    it { should be_a_directory }
  end

  describe file('/etc/rundeck/admin.aclpolicy') do
    it { should be_a_file }
  end

  describe file('/etc/rundeck/apitoken.aclpolicy') do
    it { should be_a_file }
  end

  describe file('/etc/rundeck/framework.properties') do
    it { should be_a_file }
  end
end

describe 'Service' do
  describe file('/etc/service/rundeck') do
    it { should be_a_directory }
  end

  describe port(4440) do
    it { should be_listening }
  end
end

describe 'Project teapot' do
  describe command('rd-jobs list --project teapot') do
    its(:stdout) { should match(/^- short - 'Utah teapot'/) }
  end

  describe command('rd-jobs --project teapot --name short --file /dev/stdout --format yaml') do
    it { should return_exit_status(0) }
    its(:stdout) { should include('description: I dunno') }
  end
end

describe 'Project cron' do
  describe command('rd-jobs list --project cron') do
    its(:stdout) { should match(/^- crontab/) }
    its(:stdout) { should match(/^- cron-verbose/) }
  end

  describe command('rd-jobs --project cron --name crontab --file /dev/stdout --format yaml') do
    it { should return_exit_status(0) }
    its(:stdout) { should include("seconds: '2'") }
    its(:stdout) { should include("minute: '3'") }
    its(:stdout) { should include("hour: '5'") }
    #its(:stdout) { should include("month: '5'") } # Pending https://github.com/rundeck/rundeck/issues/774
    its(:stdout) { should include("day: '7'") }
  end

  describe command('rd-jobs --project cron --name cron-verbose --file /dev/stdout --format yaml') do
    it { should return_exit_status(0) }
    its(:stdout) { should include("seconds: '17'") }
    its(:stdout) { should include("minute: '19'") }
    its(:stdout) { should include("hour: '23'") }
    #its(:stdout) { should include("month: '2'") } # Pending https://github.com/rundeck/rundeck/issues/774
    its(:stdout) { should include("day: '6'") }
  end
end
