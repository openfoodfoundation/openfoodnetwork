# frozen_string_literal: true

require 'spec_helper'

describe ReportJob do
  let(:report_args) { [report_class, user, params, format] }
  let(:report_class) { Reporting::Reports::UsersAndEnterprises::Base }
  let(:user) { enterprise.owner }
  let(:enterprise) { create(:enterprise) }
  let(:params) { {} }
  let(:format) { :csv }
  let(:configured_job) { instance_double(ActiveJob::ConfiguredJob) }

  it "generates a report" do
    job = ReportJob.new
    job.perform(*report_args)
    expect_csv_report(job)
  end

  it "enqueues a job for asynch processing" do
    job = ReportJob.perform_later(*report_args)
    expect(job.done?).to eq false

    perform_enqueued_jobs(only: ReportJob)

    expect(job.done?).to eq true
    expect_csv_report(job)
  end

  it 'sets a purge job on blob creation' do
    allow(ActiveStorage::PurgeJob).to receive(:set).and_return(configured_job)
    allow(configured_job).to receive(:perform_later)
    job = ReportJob.new
    job.perform(*report_args)
    job.result

    expect(ActiveStorage::PurgeJob).to have_received(:set).with(hash_including(:wait))
  end

  def expect_csv_report(job)
    blob = job.result
    table = CSV.parse(blob.download)
    expect(table[0][1]).to eq "Relationship"
    expect(table[1][1]).to eq "owns"
  end
end
