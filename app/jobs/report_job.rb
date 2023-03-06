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
    @result ||= read_result
  end

  private

  def write(result)
    File.write(filename, result, mode: "wb")
  end

  def read_result
    File.read(filename)
  ensure
    File.unlink(filename)
  end

  def filename
    Rails.root.join("tmp/report-#{job_id}")
  end
end
