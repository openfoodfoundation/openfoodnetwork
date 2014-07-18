DB2Fog.config = {
  :aws_access_key_id     => Spree::Config[:s3_access_key],
  :aws_secret_access_key => Spree::Config[:s3_secret],
  :directory             => "db-backup_#{Spree::Config[:s3_bucket]}",
  :provider              => 'AWS'
}
