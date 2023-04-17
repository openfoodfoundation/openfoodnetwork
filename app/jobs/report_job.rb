# frozen_string_literal: true

# Renders a report and stores it in a given blob.
class ReportJob < ApplicationJob
  def perform(report_class, user, params, format, blob)
    report = report_class.new(user, params, render: true)
    result = report.render_as(format)
    blob.store(result)
    email_result
  end

  def email_result
    ReportMailer.report_ready.deliver_later
  end
end
