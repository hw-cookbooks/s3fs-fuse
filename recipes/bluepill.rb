include_recipe "bluepill"

mounted_directories = node['s3fs-fuse'][:mounts]
if(mounted_directories.is_a?(Hash) || !mounted_directories.respond_to?(:each))
  mounted_directories = [node['s3fs-fuse'][:mounts]].compact
end

template "/etc/bluepill/s3fs.pill" do
  source "bluepill-s3fs.erb"
  variables(
    :mounted_directories => mounted_directories,
    :maxmemory => node['s3fs-fuse'][:maxmemory]
  )
  notifies :restart, 'service[s3fs-bluepill]'
end

template "/etc/init/s3fs-fuse.conf" do
  source "upstart-s3fs.erb"
  notifies :stop, 'service[s3fs-fuse]'
  notifies :start, 'service[s3fs-fuse]'
end

service "s3fs-bluepill" do
  start_command "bluepill s3fs start"
  stop_command "bluepill s3fs stop"
  restart_command "bluepill s3fs restart"
  action :nothing
end

service "s3fs-fuse" do
  provider Chef::Provider::Service::Upstart
  supports :status => true, :restart => true, :reload => true
  action [:enable, :start]
end
