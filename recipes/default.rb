#
# Cookbook Name:: monitor
# Recipe:: default
#
# Copyright 2013, Sean Porter Consulting
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

include_recipe "monitor::_master_search"

include_recipe "sensu::default"

ip_type = node["monitor"]["use_local_ipv4"] ? "local_ipv4" : "public_ipv4"

client_attributes = node["monitor"]["additional_client_attributes"].to_hash

tags_subs = []
if node.attribute?('tags') 
  tags_subs = node['tags'].select{ |tag| tag.index('sensu_') == 0  }.map do |tag|
    tag[tag.index('_') + 1..-1]
  end
end

sensu_client node.name do
  if node.has_key?("cloud")
    address node["cloud"][ip_type] || node["ipaddress"]
  else
    address node["ipaddress"]
  end
  subscriptions (node["roles"] + ["all", Chef::Config[:node_name]] + node['monitor']['subscriptions'] + tags_subs).uniq
  additional client_attributes
end

%w[
  check-procs.rb
  check-banner.rb
  check-http.rb
  check-log.rb
  check-mtime.rb
  check-tail.rb
  check-fs-writable.rb
].each do |default_plugin|
  cookbook_file "/etc/sensu/plugins/#{default_plugin}" do
    source "plugins/#{default_plugin}"
    mode 0755
  end
end

if node["monitor"]["use_nagios_plugins"]
  include_recipe "monitor::_nagios_plugins"
end

if node["monitor"]["use_system_profile"]
  include_recipe "monitor::_system_profile"
end

if node["monitor"]["use_statsd_input"]
  include_recipe "monitor::_statsd"
end

include_recipe "sensu::client_service"
