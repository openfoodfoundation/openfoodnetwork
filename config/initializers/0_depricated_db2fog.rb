# Depricated: this initializer contains an invalid bucket name.
# Users of DB2fog should be able to configure DB2fog without changing the code.
#
# Name your configuration file `db2fog.rb`. It will be ignored by git.
# And it will overwrite this depricated configuration.
#
# See: https://github.com/yob/db2fog
#
# TODO: Remove this file in a future release.
DB2Fog.config = {
  :aws_access_key_id     => Spree::Config[:s3_access_key],
  :aws_secret_access_key => Spree::Config[:s3_secret],
  :directory             => "db-backup_#{Spree::Config[:s3_bucket]}",
  :provider              => 'AWS'
}
