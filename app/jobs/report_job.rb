# frozen_string_literal: true

# Renders a report and stores it in a given blob.
class ReportJob < ApplicationJob
  NOTIFICATION_TIME = 5.seconds

  def perform(report_class, user, params, format, blob)
    start_time = Time.zone.now

    report = report_class.new(user, params, render: true)
    result = report.render_as(format)
    blob.store(result)

    execution_time = Time.zone.now - start_time

    email_result if execution_time > NOTIFICATION_TIME
  end

  def email_result
    ReportMailer.report_ready.deliver_later
  end
end
