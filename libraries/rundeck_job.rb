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

require 'tempfile'
require 'yaml'

require File.expand_path('../rundeck_project', __FILE__)

class Chef
  class Resource::RundeckJob < Resource
    include Poise(RundeckProject)
    actions(:enable, :disable)

    attribute(:job_name, kind_of: String, default: lazy { name.split('::').last })
    attribute(:format, equal_to: %w{xml yaml}, default: 'yaml')
    attribute('', template: true, required: true)

    def clean_content
      case format
      when 'xml'
        clean_xml_content
      when 'yaml'
        clean_yaml_content
      end
    end

    def clean_xml_content
      raise NotImplementedError
    end

    def clean_yaml_content
      jobs = YAML.load(content)
      if jobs.is_a?(Array)
        raise "File must specify a single job" if jobs.size != 1
        jobs.each do |job|
          raise "Invalid job format" unless job.is_a?(Hash)
          job.delete('id')
          job.delete('uuid')
          job.delete('project')
          job['name'] = job_name
          # Pending https://github.com/rundeck/rundeck/issues/773
          if job['schedule'] && job['schedule']['crontab']
            crontab = job['schedule'].delete('crontab').split
            # [sec, min, hour, dom, month, dow]
            job['schedule']['time'] = {
              'hour' => crontab[2],
              'minute' => crontab[1],
              'seconds' => crontab[0],
            }
            job['schedule']['month'] = crontab[4]
            if crontab[5] == '?'
              job['schedule']['dayofmonth'] = {'day' => crontab[3]}
            else
              job['schedule']['weekday'] = {'day' => crontab[5]}
            end
          end
        end
      end
      # The version of Psych in Ruby 1.9.3 generates *s as key: ! '*'
      # and Java can't parse that.
      jobs.to_yaml.gsub(/: !/, ':')
    end
  end

  class Provider::RundeckJob < Provider
    include Poise
    include Mixin::ShellOut

    def load_current_resource
      tempfile do |f|
        rd_jobs('list', '--project', new_resource.parent.project_name, '--name', new_resource.job_name, '--file', f.path, '--format', new_resource.format)
        @current_resource = Resource::RundeckJob.new(new_resource.name)
        @current_resource.job_name(new_resource.job_name)
        @current_resource.format(new_resource.format)
        @current_resource.content(f.read)
      end
    end

    def action_enable
      if new_resource.clean_content != current_resource.clean_content
        converge_by("create Rundeck job #{new_resource.job_name} in #{new_resource.parent.project_name}") do
          tempfile do |f|
            Chef::Log.error(new_resource.clean_content)
            f.write(new_resource.clean_content)
            f.close
            rd_jobs('load', '--project', new_resource.parent.project_name, '--file', f.path, '--format', new_resource.format)
          end
        end
      end
    end

    def action_disable
    end

    private

    def rd_jobs(*arguments)
      shell_out!(['rd-jobs']+arguments, environment: {'RDECK_BASE' => new_resource.parent.parent.path})
    end

    def tempfile(&block)
      tempfile = Tempfile.new('rundeck_job')
      block.call(tempfile)
    ensure
      tempfile.close! if tempfile
    end

  end
end
