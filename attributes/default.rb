node['s3fs-fuse'] = Mash.new
node['s3fs-fuse'][:s3_key] = ''
node['s3fs-fuse'][:s3_secret] = ''
node['s3fs-fuse'][:version] = '1.61'
node['s3fs-fuse'][:no_upload] = false
node['s3fs-fuse'][:mounts] = []
node['s3fs-fuse'][:bluepill] = false
node['s3fs-fuse'][:maxmemory] = 100
