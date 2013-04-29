#
# Cookbook Name:: s3fs-fuse
# Recipe:: default
#

mounted_directories = node['s3fs-fuse'][:mounts]
if(mounted_directories.is_a?(Hash) || !mounted_directories.respond_to?(:each))
  mounted_directories = [node['s3fs-fuse'][:mounts]].compact
end

mounted_directories.each do |mount_point|
  directory mount_point[:path] do
    recursive true
    action :create
	not_if { File.directory? mount_point[:path] }
  end
end

include_recipe "s3fs-fuse::install"

if(node['s3fs-fuse'][:bluepill])
  include_recipe "s3fs-fuse::bluepill"
end

unless(node['s3fs-fuse'][:bluepill])
  mounted_directories.each do |dir_info|
    mount dir_info[:path] do
      device "s3fs##{dir_info[:bucket]}"
      fstype 'fuse'
      dump 0
      pass 0
      options "allow_other,url=https://s3.amazonaws.com,passwd_file=/etc/passwd-s3fs,use_cache=#{dir_info[:tmp_store] || '/tmp/s3_cache'},retries=20#{",noupload" if dir_info[:no_upload]},#{dir_info[:read_only] ? 'ro' : 'rw'}"
      action [:mount, :enable]
      not_if "mountpoint -q #{dir_info[:path]}"
    end
  end
end


