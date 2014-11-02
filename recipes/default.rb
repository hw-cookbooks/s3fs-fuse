#
# Cookbook Name:: s3fs-fuse
# Recipe:: default
#

mounted_directories = node[:s3fs_fuse][:mounts]
if(mounted_directories.is_a?(Hash) || !mounted_directories.respond_to?(:each))
  mounted_directories = [node[:s3fs_fuse][:mounts]].compact
end

mounted_directories.each do |mount_point|
  directory mount_point[:path] do
    recursive true
    action :create
	not_if { File.directory? mount_point[:path] }
  end
end

def s3fs_fuse_installed()

  # Is s3fs installed?
  if !`which s3fs`.empty? && $? == 0
    return true # No
  end

  return false # Yes
end

def s3fs_fuse_diff_version( check_against )

  if !s3fs_fuse_installed()
    return true
  end

  if File.exists?( node[:s3fs_fuse][:version_file] )
    installed_version = File.open( node[:s3fs_fuse][:version_file], &:gets )
    if installed_version.empty? || installed_version != check_against
      # Not properly installed by this script or version is different
      return true
    end
  end

  # s3fs is installed and is the correct version
  return false
end

# Should I run install?
if node[:s3fs_fuse][:force_install] || s3fs_fuse_diff_version( node[:s3fs_fuse][:version] )
  include_recipe "s3fs-fuse::install"
end

if(node[:s3fs_fuse][:bluepill])
  include_recipe 's3fs-fuse::bluepill'
elsif(node[:s3fs_fuse][:rc_mon])
  include_recipe 's3fs-fuse::rc_mon'
else
  mounted_directories.each do |dir_info|
    mount dir_info[:path] do
      device "s3fs##{dir_info[:bucket]}"
      fstype 'fuse'
      dump 0
      pass 0
      options "allow_other,url=#{node[:s3fs_fuse][:s3_url]},passwd_file=/etc/passwd-s3fs,use_cache=#{dir_info[:tmp_store] || '/tmp/s3_cache'},retries=20#{",noupload" if dir_info[:no_upload]},#{dir_info[:read_only] ? 'ro' : 'rw'}"
      action [:mount, :enable]
      not_if "mountpoint -q #{dir_info[:path]}"
    end
  end
end
