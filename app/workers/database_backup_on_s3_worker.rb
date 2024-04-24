# frozen_string_literal: true

class DatabaseBackupOnS3Worker
  include Sidekiq::Worker

  def perform
    Rails.logger.info "Starting DatabaseBackupOnS3Service task..."
    DatabaseBackupOnS3Service.new.call
  end
end
  