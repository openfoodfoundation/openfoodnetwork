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
    job = perform_enqueued_jobs(only: ReportJob) do
      ReportJob.perform_later(*report_args)
    end
    expect_csv_report(job)
  end

  it "enqueues a job for async processing" do
    job = ReportJob.perform_later(*report_args)
    expect(job.done?).to eq false

    perform_enqueued_jobs(only: ReportJob)

    expect(job.done?).to eq true
    expect_csv_report(job)
  end

  def expect_csv_report(job)
    table = CSV.parse(job.result)
    expect(table[0][1]).to eq "Relationship"
    expect(table[1][1]).to eq "owns"
  end
end
