# frozen_string_literal: true

# Renders a report and stores it in a given blob.
class ReportJob < ApplicationJob
  include CableReady::Broadcaster
  delegate :render, to: ActionController::Base

  before_perform :enable_active_storage_urls

  NOTIFICATION_TIME = 5.seconds

  def perform(report_class:, user:, params:, format:, blob:, channel: nil)
    start_time = Time.zone.now

    report = report_class.new(user, params, render: true)
    result = report.render_as(format)
    blob.store(result)

    execution_time = Time.zone.now - start_time

    email_result(user, blob) if execution_time > NOTIFICATION_TIME

    broadcast_result(channel, format, blob) if channel
  end

  def email_result(user, blob)
    ReportMailer.with(
      to: user.email,
      blob: blob,
    ).report_ready.deliver_later
  end

  def broadcast_result(channel, format, blob)
    cable_ready[channel].inner_html(
      selector: "#report-table",
      html: actioncable_content(format, blob)
    ).broadcast
  end

  def actioncable_content(format, blob)
    return blob.result if format.to_sym == :html

    render(partial: "admin/reports/download", locals: { file_url: blob.expiring_service_url })
  end
end
