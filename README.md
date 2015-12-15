S3FS-FUSE
=========

Provides S3FS-FUSE with optional mount monitoring via bluepill.

Usage
=====

```ruby
override_attributes(
  's3fs_fuse' => {
    :version => 'v1.79'
    :s3_key => 'key',
    :s3_secret => 'secret',
    :mounts => [
      {:bucket => 'my-bucket', :path => '/mount/path', :tmp_store => '/tmp/cache'}
    ],
    :bluepill => true,
    :maxmemory => 50
  }
)

Multiple buckets can be mounted (which is why the `:mounts` attribute is an Array
of Hashes). Bluepill monitoring is optional and the maxmemory allows bluepill
to kill off and remount any s3 mounts that misbehave.

The value of node[:s3fs_fuse][:version] will attempt to download the specific tag
from the [s3fs-fuse github](https://github.com/s3fs-fuse/s3fs-fuse) for versions 1.74 and greater. 

Note: Bluepill should be considered for any s3fs built bucket that has large number
of entries within directories. Running an `ls` on these directories will cause the
mount's memory to balloon. Bluepill will happily watch for this (ballooning memory)
and remount the bucket.
