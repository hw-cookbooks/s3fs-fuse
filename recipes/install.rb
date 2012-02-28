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

prereqs = %w(
  build-essential
  libfuse-dev
  fuse-utils
  libcurl4-openssl-dev
  libxml2-dev
  mime-support
)

prereqs.each do |prereq_name|
  package prereq_name
end

s3fs_version = node['s3fs-fuse'][:version]

if(node['s3fs-fuse'][:no_upload])
  s3fs_version << '-noupload'
  source_url = 'https://bitbucket.org/chrisroberts/s3fs-no-upload/downloads/s3fs-1.61-noupload.tar.gz'
else
  source_url = "http://s3fs.googlecode.com/files/s3fs-#{s3fs_version}.tar.gz"
end

remote_file "/tmp/s3fs-#{s3fs_version}.tar.gz" do
  source source_url
  action :create
end

# NOTE: Important to note we modify the configure before running
#       to allow s3fs to build against fuse 2.8.4
bash "compile_and_install_s3fs" do
  cwd '/tmp'
  code <<-EOH
    tar -xzf s3fs-#{s3fs_version}.tar.gz
    cd s3fs-#{s3fs_version}
    sed -i 's/fuse >= 2.8.4/fuse >= 2.8.1/g' configure
    ./configure --prefix=/usr/local
    make && make install
  EOH
  not_if{ %x{s3fs --version}.to_s.split("\n").first.to_s.split.last == s3fs_version.to_s }
  if(node['s3fs-fuse'][:bluepill])
    notifies :stop, 'service[s3fs-fuse]'
    notifies :start, 'service[s3fs-fuse]'
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

