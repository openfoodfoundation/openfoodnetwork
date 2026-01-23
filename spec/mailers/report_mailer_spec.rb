# frozen_string_literal: true

RSpec.describe ReportMailer do
  describe "#report_ready" do
    subject(:mail) {
      ReportMailer.with(
        to: "current_user@example.net",
        blob:,
      ).report_ready
    }
    let(:blob) { ReportBlob.create_locally!("customers.csv", "report content") }
    let(:order) { build(:order_with_distributor) }

    context "white labelling" do
      it_behaves_like 'email with inactive white labelling', :mail
      it_behaves_like 'non-customer facing email with active white labelling', :mail
    end

    it "notifies about a report" do
      expect(mail.subject).to eq "Report ready"
      expect(mail.body).to have_content "Report ready for download"
    end

    it "notifies the user" do
      expect(mail.to).to eq ["current_user@example.net"]
    end

    it "contains a download link" do
      expect(mail.body).to have_link(
        "customers.csv",
        href: %r"^http://test\.host/rails/active_storage/disk/.*/customers\.csv$"
      )
    end
  end
end
