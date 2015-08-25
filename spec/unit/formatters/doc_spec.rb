#
# Author:: Daniel DeLeo (<dan@chef.io>)
#
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'
require 'timecop'

describe Chef::Formatters::Base do

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  after do
    Timecop.return
  end

  subject(:formatter) { 
    Timecop.freeze(Time.local(2008, 9, 9, 9, 9, 9)) do
      Chef::Formatters::Doc.new(out, err) 
    end
  }

  it "prints a policyfile's name and revision ID" do
    minimal_policyfile = {
      "revision_id"=> "613f803bdd035d574df7fa6da525b38df45a74ca82b38b79655efed8a189e073",
      "name"=> "jenkins",
      "run_list"=> [
        "recipe[apt::default]",
        "recipe[java::default]",
        "recipe[jenkins::master]",
        "recipe[policyfile_demo::default]"
      ],
      "cookbook_locks"=> { }
    }

    formatter.policyfile_loaded(minimal_policyfile)
    expect(out.string).to include("Using policy 'jenkins' at revision '613f803bdd035d574df7fa6da525b38df45a74ca82b38b79655efed8a189e073'")
  end

  it "prints cookbook name and version" do
    cookbook_version = double(name: "apache2", version: "1.2.3")
    formatter.synchronized_cookbook("apache2", cookbook_version)
    expect(out.string).to include("- apache2 (1.2.3")
  end

  it "prints only seconds when elapsed time is less than 60 seconds" do
    Timecop.freeze(2008, 9, 9, 9, 9, 19) do
      formatter.run_completed(nil)
      expect(formatter.elapsed_time).to include("10 seconds")
      expect(formatter.elapsed_time).not_to include("minutes")
      expect(formatter.elapsed_time).not_to include("hours")
    end
  end

  it "prints minutes and seconds when elapsed time is more than 60 seconds" do
    Timecop.freeze(2008, 9, 9, 9, 19, 19) do
      formatter.run_completed(nil)
      expect(formatter.elapsed_time).to include("10 minutes 10 seconds")
      expect(formatter.elapsed_time).not_to include("hours")
    end
  end

  it "prints hours, minutes and seconds when elapsed time is more than 3600 seconds" do
    Timecop.freeze(2008, 9, 9, 19, 19, 19) do
      formatter.run_completed(nil)
      expect(formatter.elapsed_time).to include("10 hours 10 minutes 10 seconds")
    end
  end
end
