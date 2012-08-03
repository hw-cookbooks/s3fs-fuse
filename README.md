S3FS-FUSE
=========

Provides S3FS-FUSE with optional mount monitoring via bluepill.

Important note
--------------

Currently this cookbook is only working on Ubuntu installs. It
has a fix for the current Ubuntu LTS to work around a FUSE issue
that was fixed in LTS without the required version increment
that S3FS-FUSE depends on. More informtion:

http://code.google.com/p/s3fs/issues/detail?id=138
https://bugs.launchpad.net/ubuntu/lucid/+source/fuse/+bug/634554

Usage
=====

```ruby
override_attributes(
  's3fs-fuse' => {
    :s3_key => 'key',
    :s3_secret => 'secret',
    :mounts => [
      {:bucket => 'my-bucket', :path => '/mount/path', :tmp_dir => '/tmp/cache'}
    ],
    :bluepill => true,
    :maxmemory => 50
  }
)

Multiple buckets can be mounted (which is why the `:mounts` attribute is an Array
of Hashes). Bluepill monitoring is optional and the maxmemory allows bluepill
to kill off and remount any s3 mounts that misbehave.

Note: Bluepill should be considered for any s3fs built bucket that has large number
of entries within directories. Running an `ls` on these directories will cause the
mount's memory to balloon. Bluepill will happily watch for this (ballooning memory)
and remount the bucket.
