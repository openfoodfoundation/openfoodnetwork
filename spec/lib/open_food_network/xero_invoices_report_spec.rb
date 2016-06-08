require 'open_food_network/xero_invoices_report'

module OpenFoodNetwork
  describe XeroInvoicesReport do
    subject { XeroInvoicesReport.new user }

    let(:user) { create(:user) }

    describe "option defaults" do
      let(:report) { XeroInvoicesReport.new user, {initial_invoice_number: '', invoice_date: '', due_date: '', account_code: ''} }

      around { |example| Timecop.travel(Time.zone.local(2015, 5, 5, 14, 0, 0)) { example.run } }

      it "uses defaults when blank params are passed" do
        report.instance_variable_get(:@opts).should == {invoice_date: Date.civil(2015, 5, 5),
                                                        due_date: Date.civil(2015, 6, 5),
                                                        account_code: 'food sales',
                                                        report_type: 'summary'}
      end
    end

    describe "summary rows" do
      let(:report) { XeroInvoicesReport.new user, {initial_invoice_number: '', invoice_date: '', due_date: '', account_code: ''} }
      let(:order) { double(:order) }
      let(:summary_rows) { report.send(:summary_rows_for_order, order, 1, {}) }

      before do
        report.stub(:produce_summary_rows)  { ['produce'] }
        report.stub(:fee_summary_rows)      { ['fee'] }
        report.stub(:shipping_summary_rows) { ['shipping'] }
        report.stub(:payment_summary_rows)  { ['payment'] }
        report.stub(:admin_adjustment_summary_rows) { ['admin'] }
        order.stub(:account_invoice?)       { false }
      end

      it "displays produce summary rows when summary report" do
        report.stub(:detail?) { false }
        summary_rows.should include 'produce'
      end

      it "does not display produce summary rows when detail report" do
        report.stub(:detail?) { true }
        summary_rows.should_not include 'produce'
      end

      it "displays fee summary rows when summary report" do
        report.stub(:detail?)         { false }
        order.stub(:account_invoice?) { true }
        summary_rows.should include 'fee'
      end

      it "displays fee summary rows when this is not an account invoice" do
        report.stub(:detail?)         { true }
        order.stub(:account_invoice?) { false }
        summary_rows.should include 'fee'
      end

      it "does not display fee summary rows when this is a detail report for an account invoice" do
        report.stub(:detail?)         { true }
        order.stub(:account_invoice?) { true }
        summary_rows.should_not include 'fee'
      end

      it "always displays shipping summary rows" do
        summary_rows.should include 'shipping'
      end

      it "displays admin adjustment summary rows when summary report" do
        summary_rows.should include 'admin'
      end

      it "does not display admin adjustment summary rows when detail report" do
        report.stub(:detail?)         { true }
        summary_rows.should_not include 'admin'
      end
    end

    describe "finding account invoice adjustments" do
      let(:report) { XeroInvoicesReport.new user, {initial_invoice_number: '', invoice_date: '', due_date: '', account_code: ''} }
      let!(:order) { create(:order) }
      let(:billable_period) { create(:billable_period) }
      let(:shipping_method) { create(:shipping_method) }
      let!(:adj_invoice)  { create(:adjustment, adjustable: order, label: 'Account invoice item', source: billable_period) }
      let!(:adj_shipping) { create(:adjustment, adjustable: order, label: "Shipping", originator: shipping_method) }

      it "returns BillablePeriod adjustments only" do
        report.send(:account_invoice_adjustments, order).should == [adj_invoice]
      end

      it "excludes adjustments where the source is missing" do
        billable_period.destroy
        report.send(:account_invoice_adjustments, order).should be_empty
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
        subject { XeroInvoicesReport.new user, {initial_invoice_number: '123'} }

        it "increments the number by the index" do
          subject.send(:invoice_number_for, order, 456).should == 579
        end
      end
    end
  end
end
