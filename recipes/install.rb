#
# Cookbook Name:: s3fs-fuse
# Recipe:: install
#

template '/etc/passwd-s3fs' do
  variables(
    :s3_key => node[:s3fs_fuse][:s3_key],
    :s3_secret => node[:s3fs_fuse][:s3_secret]
  )
  mode 0600
end

prereqs = case node.platform_family
when 'debian'
  %w(
    build-essential
    libfuse-dev
    fuse-utils
    libcurl4-openssl-dev
    libxml2-dev
    mime-support
  )
when 'rhel'
  %w(
    gcc
    libstdc++-devel
    gcc-c++
    curl-devel
    libxml2-devel
    openssl-devel
    mailcap
    fuse
    fuse-devel
    fuse-libs
  )
else
  raise "Unsupported platform family provided: #{node.platform_family}"
end

prereqs = node[:s3fs_fuse][:packages] unless node[:s3fs_fuse][:packages].empty?

prereqs.each do |prereq_name|
  package prereq_name
end

s3fs_version = node[:s3fs_fuse][:version]
# source_url = "http://s3fs.googlecode.com/files/s3fs-#{s3fs_version}.tar.gz"
#
# remote_file "/tmp/s3fs-#{s3fs_version}.tar.gz" do
#   source source_url
#   action :create_if_missing
# end

git 's3fs-fuse_github' do
  repository 'git@github.com:s3fs-fuse/s3fs-fuse.git'
  revision "v#{s3fs_version}"
  destination '/tmp'
  retries 3
  timeout 60
  action :sync
end

bash "compile_and_install_s3fs" do
  cwd '/tmp'
  code <<-EOH
    cd s3fs-fuse
    #{'export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/lib64/pkgconfig' if node.platform_family == 'rhel'}
    ./configure --prefix=/usr/local
    make && make install
  EOH
  not_if do
    begin
      %x{s3fs --version}.to_s.split("\n").first.to_s.split.last == s3fs_version.to_s
    rescue Errno::ENOENT
      false
    end
  end
  if(node[:s3fs_fuse][:bluepill] && File.exists?(File.join(node[:bluepill][:conf_dir], 's3fs.pill')))
    notifies :stop, 'bluepill_service[s3fs]'
    notifies :start, 'bluepill_service[s3fs]'
  end
end

bash "load_fuse" do
  code <<-EOH
    modprobe fuse
  EOH
  not_if{
    system('lsmod | grep fuse > /dev/null') ||
    system('cat /boot/config-`uname -r` | grep -P "^CONFIG_FUSE_FS=y$" > /dev/null')
  }
end
