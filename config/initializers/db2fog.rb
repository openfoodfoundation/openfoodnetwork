require_relative 'spree'

Rails.application.reloader.to_prepare do
  # See: https://github.com/openfoodfoundation/db2fog
  DB2Fog.config = {
      :aws_access_key_id     => Spree::Config[:s3_access_key],
      :aws_secret_access_key => Spree::Config[:s3_secret],
      :directory             => ENV['S3_BACKUPS_BUCKET'],
      :provider              => 'AWS'
  }

  region = ENV['S3_BACKUPS_REGION'] || ENV['S3_REGION']

  # If no region is defined we leave this config key undefined (instead of nil),
  # so that db2fog correctly applies it's default
  DB2Fog.config[:region] = region if region
end
