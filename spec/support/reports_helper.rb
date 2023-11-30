# frozen_string_literal: true

module ReportsHelper
  def run_report
    click_on "Go"
    expect(page).to have_selector ".loading"
    perform_enqueued_jobs(only: ReportJob)
    expect(page).to have_no_selector ".loading"
  end
end
