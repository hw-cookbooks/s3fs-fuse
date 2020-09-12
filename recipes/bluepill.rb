include_recipe 'bluepill'

if File.exist?('/etc/init/s3fs-fuse.conf')
  service 's3fs-fuse' do
    provider Chef::Provider::Service::Upstart
    action :stop
  end

  file '/etc/init/s3fs-fuse.conf' do
    action :delete
  end
end

mounted_directories = node['s3fs_fuse']['mounts']
if mounted_directories.is_a?(Hash) || !mounted_directories.respond_to?(:each)
  mounted_directories = [node['s3fs_fuse']['mounts']].compact
end

execute 's3fs[bluepill-forced-load]' do
  command "bluepill load #{File.join(node['bluepill']['conf_dir'], 's3fs.pill')}"
  action :nothing
end

template File.join(node['bluepill']['conf_dir'], 's3fs.pill') do
  source 'bluepill-s3fs.erb'
  variables(
    mounted_directories: mounted_directories,
    maxmemory: node['s3fs_fuse']['maxmemory'],
    pid_dir: File.join(node['bluepill']['pid_dir'], 'pids')
  )
  notifies :run, 'execute[s3fs[bluepill-forced-load]]', :immediately
end

bluepill_service 's3fs' do
  action [:enable, :load, :start]
end
