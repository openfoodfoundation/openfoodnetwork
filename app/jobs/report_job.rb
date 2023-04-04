# frozen_string_literal: true

# Renders a report and stores it in a given blob.
class ReportJob < ApplicationJob
  def self.create_blob!
    # ActiveStorage discourages modifying a blob later but we need a blob
    # before we know anything about the report file. It enables us to use the
    # same blob in the controller to read the result.
    ActiveStorage::Blob.create_before_direct_upload!(
      filename: "tbd",
      byte_size: 0,
      checksum: "0",
      content_type: "application/octet-stream",
    ).tap do |blob|
      ActiveStorage::PurgeJob.set(wait: 1.month).perform_later(blob)
    end
  end

  def perform(report_class, user, params, format, blob)
    report = report_class.new(user, params, render: true)
    result = report.render_as(format)
    write(result, blob)
  end

  def done?
    @done ||= blob.reload.checksum != "0"
  end

  def result
    @result ||= read_result
  end

  private

  def write(result, blob)
    io = StringIO.new(result)
    blob.upload(io, identify: false)
    blob.save!
  end

  def read_result
    blob.download
  end

  def blob
    arguments[4]
  end
end
