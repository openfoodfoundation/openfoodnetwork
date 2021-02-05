# encoding: utf-8
# Backup v5.x Configuration

app_config = YAML.load_file(File.join(__dir__, 'application.yml'))
db_config = YAML.load_file(File.join(__dir__, 'database.yml'))

Backup::Model.new(:s3_backup, 'Backup to Amazon S3') do

  environment = ENV.fetch("RAILS_ENV")

  database PostgreSQL do |db|
    db.name               = db_config[environment]["database"]
    db.username           = db_config[environment]["username"]
    db.password           = db_config[environment]["password"]
    db.host               = db_config[environment]["host"]
    db.port               = 5432
    db.additional_options = ["-xc", "-E=utf8"]
  end

  store_with S3 do |s3|
    s3.access_key_id     = app_config["S3_ACCESS_KEY"]
    s3.secret_access_key = app_config["S3_SECRET"]
    s3.region            = app_config["S3_BACKUPS_REGION"]
    s3.bucket            = app_config["S3_BACKUPS_BUCKET"]
    s3.keep              = 10
  end

  compress_with Gzip
end
