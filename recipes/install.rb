#
# Cookbook Name:: s3fs-fuse
# Recipe:: install
#

template '/etc/passwd-s3fs' do
  variables(
    :s3_key => node['s3fs-fuse'][:s3_key],
    :s3_secret => node['s3fs-fuse'][:s3_secret]
  )
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
  )
else
  raise "Unsupported platform family provided: #{node.platform_family}"
end

prereqs.each do |prereq_name|
  package prereq_name
end

# If we're in redhat land and fuse is ancient, update it
if(node.platform_family == 'rhel')
  %w(fuse fuse* fuse-devel).each do |pkg_name|
    package pkg_name do
      action :remove
    end
  end

  fuse_version = File.basename(node['s3fs-fuse'][:fuse_url]).match(/\d\.\d\.\d/).to_s
  #TODO: /bin/true is an ugly hack
  fuse_check = [
    {'PKG_CONFIG_PATH' => '/usr/lib/pkgconfig:/usr/lib64/pkgconfig'},
    '/usr/bin/pkg-config',
    '--modversion',
    'fuse'
  ]

  remote_file "/tmp/#{File.basename(node['s3fs-fuse'][:fuse_url])}" do
    source "#{node['s3fs-fuse'][:fuse_url]}?ts=#{Time.now.to_i}&use_mirror=#{node['s3fs-fuse'][:fuse_mirror]}"
    action :create_if_missing
    not_if do
      IO.popen(fuse_check).readlines.join('').strip == fuse_version
    end
  end

  bash "compile_and_install_fuse" do
    cwd '/tmp'
    code <<-EOH
      tar -xzf fuse-#{fuse_version}.tar.gz
      cd fuse-#{fuse_version}
      ./configure --prefix=/usr
      make
      make install
      export PKG_CONFIG_PATH=/usr/lib/pkgconfig:/usr/lib64/pkgconfig
      ldconfig
      modprobe fuse
    EOH
    not_if do
      IO.popen(fuse_check).readlines.join('').strip == fuse_version
    end
  end

end

s3fs_version = node['s3fs-fuse'][:version]
source_url = "http://s3fs.googlecode.com/files/s3fs-#{s3fs_version}.tar.gz"

remote_file "/tmp/s3fs-#{s3fs_version}.tar.gz" do
  source source_url
  action :create_if_missing
end

bash "compile_and_install_s3fs" do
  cwd '/tmp'
  code <<-EOH
    tar -xzf s3fs-#{s3fs_version}.tar.gz
    cd s3fs-#{s3fs_version}
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
  if(node['s3fs-fuse'][:bluepill] && File.exists?(File.join(node[:bluepill][:conf_dir], 's3fs.pill')))
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

