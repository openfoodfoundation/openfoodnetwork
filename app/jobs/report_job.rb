# frozen_string_literal: true

# Renders a report and saves it to a temporary file.
class ReportJob < ActiveJob::Base
  def perform(report_class, user, params, format)
    report = report_class.new(user, params, render: true)
    result = report.render_as(format)
    write(result)
  end

  def done?
    @done ||= File.file?(filename)
  end

  def result
    blob = ActiveStorage::Blob.create_and_upload!(io: File.open(filename), filename: filename)
    ActiveStorage::PurgeJob
      .set(wait: Rails.configuration.active_storage.service_urls_expire_in)
      .perform_later(blob)
    File.unlink(filename)
    blob
  end

  private

  def write(result)
    File.write(filename, result, mode: "wb")
  end

  def filename
    Rails.root.join("tmp/report-#{job_id}")
  end
end
