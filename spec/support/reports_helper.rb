# frozen_string_literal: true

module ReportsHelper
  def run_report
    click_on "Go"
    perform_enqueued_jobs(only: ReportJob)
  end
end
