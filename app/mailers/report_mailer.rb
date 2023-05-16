# frozen_string_literal: true

class ReportMailer < ApplicationMailer
  def report_ready
    # When we are in a background job then we don't have an HTTP request object
    # and we need to tell ActiveStorage the hostname to generate URLs.
    ActiveStorage::Current.url_options ||= url_options

    @blob = params[:blob]
    mail(params)
  end
end
