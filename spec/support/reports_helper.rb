# frozen_string_literal: true

module ReportsHelper
  def run_report
    click_on "Go"

    go_button = find("button.report__submit-btn")
    expect(go_button).to be_disabled
    expect(page).to have_selector ".loading"

    perform_enqueued_jobs(only: ReportJob)

    expect(page).not_to have_selector ".loading"
    expect(go_button).not_to be_disabled
  end
end
