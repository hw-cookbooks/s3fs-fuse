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

s3fs_git_tag         = node[:s3fs_fuse][:version]
s3fs_numeric_version = node[:s3fs_fuse][:version].tr('^0-9.','')

puts s3fs_numeric_version.to_f.to_s

if s3fs_numeric_version.to_f >= 1.74
  source_url = "https://github.com/s3fs-fuse/s3fs-fuse/tarball/tags/#{s3fs_git_tag}"
else
  source_url = "http://s3fs.googlecode.com/files/s3fs-#{s3fs_git_tag}.tar.gz"
end


remote_file "/tmp/s3fs-#{s3fs_git_tag}.tar.gz" do
  source source_url
  action :create_if_missing
end

bash "compile_and_install_s3fs" do
  cwd '/tmp'
  code <<-EOH
    mkdir s3fs-#{s3fs_git_tag}
    tar -xzf s3fs-#{s3fs_git_tag}.tar.gz -C s3fs-#{s3fs_git_tag} --strip-components 1
    cd s3fs-#{s3fs_git_tag}
    #{'export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/lib64/pkgconfig' if node.platform_family == 'rhel'}
    ./configure --prefix=/usr/local
    make && make install
  EOH
  not_if do
    begin
      %x{s3fs --version}.to_s.split("\n").first.to_s.split.last == s3fs_numeric_version.to_s
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
