# frozen_string_literal: true

class DatabaseBackupOnS3Service
  def call
    bucket_name = ENV.fetch('DB_BUCKET_NAME', 'database-backups')
    object_key = "#{Time.now.to_i}_open_food_network_dev.sql"

    pg_dump_command = "PGPASSWORD=#{ENV.fetch('OFN_DB_PASSWORD', 'f00d')} pg_dump -Fc -Z9 -U #{ENV.fetch('OFN_DB_USERNAME', 'ofn')} -h #{ENV.fetch('OFN_DB_HOST', 'localhost')} #{ENV.fetch('OFN_DB_NAME', 'openfoodnetwork')} > #{object_key}"
    system(pg_dump_command)

    # Upload the backup file to S3
    aws_copy_command = "aws --profile eu2 --region default --endpoint-url https://eu2.contabostorage.com s3 cp #{object_key} s3://#{bucket_name}"
    system(aws_copy_command)

    Rails.logger.debug { "Backup successfully uploaded to S3 bucket: #{bucket_name}/#{object_key}" }

    # Delete the local backup file after uploading to S3
    File.delete(object_key)
    Rails.logger.debug "Local backup file deleted."
  end
end