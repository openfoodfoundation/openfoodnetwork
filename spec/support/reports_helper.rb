# frozen_string_literal: true

module ReportsHelper
  def run_report
    click_on "Go"

    expect(page).to have_button "Go", disabled: true
    expect(page).to have_selector ".loading"

    perform_enqueued_jobs(only: ReportJob)

    expect(page).not_to have_selector ".loading"
    expect(page).to have_button "Go", disabled: false
  end

  def run_failed_report(report)
    click_on "Go"

    allow(report).to receive(:new).and_raise(StandardError, 'Provoked error for testing')
    perform_enqueued_jobs(only: ReportJob)

    expect(page).not_to have_selector ".loading"
    expect(page).to have_button "Go", disabled: false
    expect(page).to have_content 'This report failed. It may be too big to process. ' \
                                 'We will look into it but please let us know ' \
                                 'if the problem persists.'
  end

  def generate_report
    run_report
    click_on "Download Report"
    wait_for_download
  end

  def load_file_txt(extension, downloaded_filename)
    case extension
    when "csv"
      CSV.read(downloaded_filename).join(" ")
    when "xlsx"
      xlsx = Roo::Excelx.new(downloaded_filename)
      xlsx.map(&:to_a).join(" ")
    end
  end

  def table_headers
    rows = find("table.report__table").all("thead tr")
    rows.map { |r| r.all("th").map { |c| c.text.strip } }
  end
end
