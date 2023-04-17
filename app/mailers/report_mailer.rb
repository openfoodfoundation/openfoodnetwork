# frozen_string_literal: true

class ReportMailer < ApplicationMailer
  def report_ready
    mail
  end
end
