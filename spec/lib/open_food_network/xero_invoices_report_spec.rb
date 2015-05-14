require 'open_food_network/xero_invoices_report'

module OpenFoodNetwork
  describe XeroInvoicesReport do
    subject { XeroInvoicesReport.new [] }

    describe "generating invoice numbers" do
      let(:order) { double(:order, number: 'R731032860') }

      describe "when no initial invoice number is given" do
        it "returns the order number" do
          subject.send(:invoice_number_for, order, 123).should == 'R731032860'
        end
      end

      describe "when an initial invoice number is given" do
        subject { XeroInvoicesReport.new [], {initial_invoice_number: '123'} }

        it "increments the number by the index" do
          subject.send(:invoice_number_for, order, 456).should == 579
        end
      end
    end
  end
end
