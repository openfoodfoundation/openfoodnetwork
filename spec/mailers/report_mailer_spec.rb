# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReportMailer do
  describe "#report_ready" do
    subject(:email) {
      ReportMailer.with(
        to: "current_user@example.net",
        blob:,
      ).report_ready
    }
    let(:blob) { ReportBlob.create_locally!("customers.csv", "report content") }

    it "notifies about a report" do
      expect(email.subject).to eq "Report ready"
      expect(email.body).to have_content "Your report is ready for download."
    end

    it "notifies the user" do
      expect(email.to).to eq ["current_user@example.net"]
    end

    it "contains a download link" do
      expect(email.body).to have_link(
        "customers.csv",
        href: %r"^http://test\.host/rails/active_storage/disk/.*/customers\.csv$"
      )
    end
  end
end
