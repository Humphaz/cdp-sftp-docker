docker run -d \
  --name sftp_server \
  -p 2211:22 \
  -v /data/sftp:/data/sftp \
  -v /data/config/sftp:/data/config/sftp \
  sftp_image

