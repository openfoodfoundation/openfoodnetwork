# frozen_string_literal: true

RSpec.describe BulkInvoiceJob do
  subject { BulkInvoiceJob.new(order_ids, "/tmp/file/path") }

  context "when invoices are enabled", feature: :invoices do
    describe "#perform" do
      let!(:order1) { create(:shipped_order) }
      let!(:order2) { create(:shipped_order) }
      let!(:order3) { create(:order_ready_to_ship) }
      let(:order_ids) { [order3.id, order1.id, order2.id] }
      let(:path){ "/tmp/file/path.pdf" }

      before do
        allow(TermsOfServiceFile).to receive(:current_url).and_return("http://example.com/terms.pdf")
        order3.cancel
        order3.resume
      end

      it "should generate invoices for given order ids" do
        expect{
          subject.perform(order_ids, path)
        }.to change{ order1.invoices.count }.from(0).to(1)
          .and change{ order2.invoices.count }.from(0).to(1)
          .and change{ order3.invoices.count }.from(0).to(1)

        pages = File.open(path, "rb") do |io|
          reader = PDF::Reader.new(io)
          reader.pages.map(&:text)
        end

        # Pages should be in the order of order ids given:
        expect(pages[0]).to include(order3.number)
        expect(pages[1]).to include(order1.number)
        expect(pages[2]).to include(order2.number)
      end
    end
  end
end
