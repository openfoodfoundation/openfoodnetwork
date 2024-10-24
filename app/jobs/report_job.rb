# frozen_string_literal: true

# Renders a report and stores it in a given blob.
class ReportJob < ApplicationJob
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
  rescue StandardError => e
    Bugsnag.notify(e) do |payload|
      payload.add_metadata :report, {
        report_class:, user:, params:, format:
      }
    end

    broadcast_error(channel)
  end

  def email_result(user, blob)
    ReportMailer.with(
      to: user.email,
      blob:,
    ).report_ready.deliver_later
  end

  def broadcast_result(channel, format, blob)
    ActionCable.server.broadcast(
      channel,
      {
        selector: "#report-go",
        html: Spree::Admin::BaseController.helpers.button(I18n.t(:go), "report__submit-btn")
      }
    )

    ActionCable.server.broadcast(
      channel,
      { selector: "#report-table", html: actioncable_content(format, blob) }
    )
  end

  def broadcast_error(channel)
    ActionCable.server.broadcast(
      channel,
      { selector: "#report-table", html: I18n.t("report_job.report_failed") }
    )
  end

  def actioncable_content(format, blob)
    if format.to_sym == :html
      return blob.result if blob.byte_size < 10**6 # 1 MB

      return render(
        partial: "admin/reports/display",
        locals: { file_url: blob.expiring_service_url }
      )
    end

    render(partial: "admin/reports/download", locals: { file_url: blob.expiring_service_url })
  end
end
