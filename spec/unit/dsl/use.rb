#
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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

require "spec_helper"
require "chef/dsl/recipe"

module MyAwesomeDSLExensionClass
  def my_awesome_dsl_extension(argument)
    argument
  end
end

class MyAwesomeResource < Chef::Resource::LWRPBase
  provides :my_awesome_resource
  resource_name :my_awesome_resource
  default_action :create
end

class MyAwesomeProvider < Chef::Provider::LWRPBase
  use_inline_resources

  provides :my_awesome_resource

  action :create do
    my_awesome_dsl_extension("foo")
  end
end

describe Chef::DSL::Use do
  let(:recipe) {
    cookbook_repo = File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "cookbooks"))
    cookbook_loader = Chef::CookbookLoader.new(cookbook_repo)
    cookbook_loader.load_cookbooks
    cookbook_collection = Chef::CookbookCollection.new(cookbook_loader)
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, cookbook_collection, events)
    Chef::Recipe.new("hjk", "test", run_context)
  }

  it "lets you extend the recipe DSL" do
    expect(Chef::Recipe).to receive(:include).with(MyAwesomeDSLExensionClass)
    expect(Chef::Provider::InlineResources).to receive(:include).with(MyAwesomeDSLExensionClass)
    recipe.use(MyAwesomeDSLExensionClass)
  end

  it "lets you call your DSL from a recipe" do
    recipe.use(MyAwesomeDSLExensionClass)
    expect(recipe.my_awesome_dsl_extension("foo")).to eql("foo")
  end

  it "lets you call your DSL from a provider" do
    recipe.use(MyAwesomeDSLExensionClass)

    resource = MyAwesomeResource.new("name", run_context)
    run_context.resource_collection << resource

    runner = Chef::Runner.new(run_context)
    expect_any_instance_of(MyAwesomeProvider).to receive(:my_awesome_dsl_extension).and_call_original
    runner.converge
  end
end
