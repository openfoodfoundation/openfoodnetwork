# frozen_string_literal: true

require 'aws-sdk-s3'

class DatabaseBackupOnS3Service
  def self.perform_backup
    new.perform
  end

  def perform
    setup_environment
    create_database_dump
    upload_to_s3
  ensure
    cleanup
  end

  private

  def setup_environment
    @bucket_name = ENV.fetch('DB_BUCKET_NAME', 'database-backups')
    @object_key = "#{Time.now.to_i}_open_food_network_backup.sql"
    @db_dump_path = Rails.root.join(@object_key)
  end

  def create_database_dump
    pg_dump_command = "PGPASSWORD=#{ENV.fetch('OFN_DB_PASSWORD',
                                              'f00d')} pg_dump -Fc -Z9 -U #{ENV.fetch('OFN_DB_USERNAME',
                                                                                      'ofn')} -h #{ENV.fetch('OFN_DB_HOST',
                                                                                                             'localhost')} #{ENV.fetch(
                                                                                                               'OFN_DB_NAME', 'openfoodnetwork'
                                                                                                             )} > #{@object_key}"
    system(pg_dump_command) or raise "Database dump failed"
  end

  def upload_to_s3
    s3 = Aws::S3::Resource.new(
      credentials: Aws::Credentials.new(ENV.fetch('aws_access_key_id', ''),
                                        ENV.fetch('aws_secret_access_key', '')),
      endpoint: 'https://eu2.contabostorage.com',
      region: 'eu-west-2',  # Adjust the region if necessary
      force_path_style: true
    )
    obj = s3.bucket(@bucket_name).object(@object_key)
    obj.upload_file(@db_dump_path.to_s)
    Rails.logger.info "Backup successfully uploaded to S3 bucket: #{@bucket_name}/#{@object_key}"
  end

  def cleanup
    FileUtils.rm_f(@db_dump_path)
    Rails.logger.info "Local backup file deleted."
  rescue StandardError => e
    Rails.logger.error "Failed to delete local backup file: #{e.message}"
  end
end
