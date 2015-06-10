require 'open_food_network/xero_invoices_report'

module OpenFoodNetwork
  describe XeroInvoicesReport do
    subject { XeroInvoicesReport.new [] }

    describe "option defaults" do
      let(:report) { XeroInvoicesReport.new [], {initial_invoice_number: '', invoice_date: '', due_date: '', account_code: ''} }

      around { |example| Timecop.travel(Time.zone.local(2015, 5, 5, 14, 0, 0)) { example.run } }

      it "uses defaults when blank params are passed" do
        report.instance_variable_get(:@opts).should == {invoice_date: Date.civil(2015, 5, 5),
                                                        due_date: Date.civil(2015, 5, 19),
                                                        account_code: 'food sales'}
      end
    end

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
