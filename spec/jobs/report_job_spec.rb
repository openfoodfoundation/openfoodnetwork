# frozen_string_literal: true

require 'spec_helper'

describe ReportJob do
  let(:report_args) {
    { report_class: report_class, user: user, params: params, format: format,
      blob: blob }
  }
  let(:report_class) { Reporting::Reports::UsersAndEnterprises::Base }
  let(:user) { enterprise.owner }
  let(:enterprise) { create(:enterprise) }
  let(:params) { {} }
  let(:format) { :csv }
  let(:blob) { ReportBlob.create_for_upload_later!("report.csv") }

  it "generates a report" do
    job = perform_enqueued_jobs(only: ReportJob) do
      ReportJob.perform_later(**report_args)
    end
    expect_csv_report
  end

  it "enqueues a job for async processing" do
    job = ReportJob.perform_later(**report_args)
    expect(blob.content_stored?).to eq false

    perform_enqueued_jobs(only: ReportJob)

    expect(blob.content_stored?).to eq true
    expect_csv_report
  end

  it "triggers an email when the report is done" do
    # Setup test data which also triggers emails:
    report_args

    # Send emails for quick jobs as well:
    stub_const("ReportJob::NOTIFICATION_TIME", 0)

    expect {
      # We need to create this job within the block because of a bug in
      # rspec-rails: https://github.com/rspec/rspec-rails/issues/2668
      ReportJob.perform_later(**report_args)
      perform_enqueued_jobs(only: ReportJob)
    }.to enqueue_mail(ReportMailer, :report_ready).with(
      params: {
        to: user.email,
        blob: blob,
      },
      args: [],
    )
  end

  it "triggers no email when the report is done quickly" do
    # Setup test data which also triggers emails:
    report_args

    expect {
      # We need to create this job within the block because of a bug in
      # rspec-rails: https://github.com/rspec/rspec-rails/issues/2668
      ReportJob.perform_later(**report_args)
      perform_enqueued_jobs(only: ReportJob)
    }.to_not enqueue_mail
  end

  def expect_csv_report
    blob.reload
    expect(blob.filename.to_s).to eq "report.csv"
    expect(blob.content_type).to eq "text/csv"

    table = CSV.parse(blob.result)
    expect(table[0][1]).to eq "Relationship"
    expect(table[1][1]).to eq "owns"
  end
end
