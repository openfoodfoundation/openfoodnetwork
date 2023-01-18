# frozen_string_literal: true

require 'spec_helper'

describe ReportJob do
  let(:report_args) { [report_class, user, params, format] }
  let(:report_class) { Reporting::Reports::UsersAndEnterprises::Base }
  let(:user) { enterprise.owner }
  let(:enterprise) { create(:enterprise) }
  let(:params) { {} }
  let(:format) { :csv }

  it "generates a report" do
    job = ReportJob.new
    job.perform(*report_args)
    expect_csv_report(job)
  end

  it "enqueues a job for asynch processing" do
    job = ReportJob.perform_later(*report_args)
    expect(job.done?).to eq false

    # This performs the job in the same process but that's good enought for
    # testing the job code. I hope that we can rely on the job worker.
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
    job.retry_job

    expect(job.done?).to eq true
    expect_csv_report(job)
  end

  def expect_csv_report(job)
    table = CSV.parse(job.result)
    expect(table[0][1]).to eq "Relationship"
    expect(table[1][1]).to eq "owns"
  end
end
