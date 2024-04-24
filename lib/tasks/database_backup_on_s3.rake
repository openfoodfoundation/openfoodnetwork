# frozen_string_literal: true

desc "DB backup on S3 bucket"
task database_backup_on_s3: :environment do
  DatabaseBackupOnS3Worker.perform_async
end
