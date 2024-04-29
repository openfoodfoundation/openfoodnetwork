# frozen_string_literal: true

require 'aws-sdk-s3'
require 'pg'

class DatabaseRestoreService
  def self.restore_backup
    new.restore
  end

  def restore
    setup_environment
    download_latest_backup
    create_new_database
    restore_database_from_dump
    @new_db_name
  ensure
    cleanup
  end

  private

  def setup_environment
    @bucket_name = ENV.fetch('DB_BUCKET_NAME', 'database-backups')
    @s3 = Aws::S3::Resource.new(
      credentials: Aws::Credentials.new(ENV.fetch('aws_access_key_id', ''),
                                        ENV.fetch('aws_secret_access_key', '')),
      endpoint: 'https://eu2.contabostorage.com',
      region: 'eu-west-2',  # Adjust the region if necessary
      force_path_style: true
    )
    @backup_dir = Rails.root.join("tmp/backups")
    FileUtils.mkdir_p(@backup_dir)
  end

  def download_latest_backup
    bucket = @s3.bucket(@bucket_name)
    @backup_file = bucket.objects.max_by(&:last_modified)
    @local_path = File.join(@backup_dir, @backup_file.key)
    @backup_file.get(response_target: @local_path)
    Rails.logger.info "Backup successfully downloaded: #{@local_path}"
  end

  def create_new_database
    @new_db_name = "#{ENV.fetch('OFN_DB_NAME',
                                'openfoodnetwork')}_restored_#{Time.zone.now.strftime('%Y%m%d%H%M%S')}"
    system("psql -c 'CREATE DATABASE #{@new_db_name}' -h #{ENV.fetch('OFN_DB_HOST',
                                                                     'localhost')} -U #{ENV.fetch(
                                                                       'OFN_DB_USERNAME', 'ofn'
                                                                     )} -d postgres")
    Rails.logger.info "New database created: #{@new_db_name}"
  end

  def restore_database_from_dump
    restore_command = "PGPASSWORD=#{ENV.fetch('OFN_DB_PASSWORD',
                                              'f00d')} pg_restore -d #{@new_db_name} -h #{ENV.fetch('OFN_DB_HOST',
                                                                                                    'localhost')} -U #{ENV.fetch(
                                                                                                      'OFN_DB_USERNAME', 'ofn'
                                                                                                    )} #{@local_path}"
    system(restore_command)
    Rails.logger.info "Database successfully restored to #{@new_db_name}"
  end

  def cleanup
    FileUtils.rm_f(@local_path)
    Rails.logger.info "Local backup file deleted."
  rescue StandardError => e
    Rails.logger.error "Failed to delete local backup file: #{e.message}"
  end
end
