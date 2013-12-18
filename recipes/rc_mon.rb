
node[:s3fs_fuse][:mounts].each do |mount|
  mount_command = ["s3fs -f #{mount[:bucket]} #{mount[:path]} -o allow_other"]
  mount_command << "url=#{File.join(node[:s3fs_fuse][:s3_url])}"
  mount_command << "passwd_file=/etc/passwd-s3fs"
  mount_command << "use_cache=#{mount[:tmp_store] || '/tmp/s3_cache'}"
  mount_command << "retries=20"
  mount_command << "dev"
  mount_command << "suid"
  if(mount[:no_upload])
    mount_command << "noupload"
  end
  mount_command << mount[:read_only] ? 'ro' : 'rw'

  rc_mon_service "s3fs-#{mount[:path].gsub('/', '-')}" do
    start_command mount_command.join(',')
    stop_command "umount #{mount[:path]}"
    memory_limit "#{mount[:maxmemory]}M"
  end

end
