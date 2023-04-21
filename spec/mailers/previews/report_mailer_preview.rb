# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/report_mailer
class ReportMailerPreview < ActionMailer::Preview
  def report_ready
    ReportMailer.with(
      blob: ReportBlob.last,
    ).report_ready
  end
end
