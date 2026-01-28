# frozen_string_literal: true

RSpec.describe Reporting::Reports::OrdersAndFulfillment::OrderCycleCustomerTotals do
  let!(:distributor) { create(:distributor_enterprise, name: "Apple Market") }
  let!(:customer) { create(:customer, enterprise: distributor, user:, code: "JHN") }
  let(:user) { create(:user, email: "john@example.net") }
  let(:current_user) { distributor.owner }
  let(:params) { { display_summary_row: true, q: search_params } }
  let(:search_params) {
    { completed_at_gt: 1.week.before(order_date), completed_at_lt: 1.week.after(order_date) }
  }
  let(:report) { described_class.new(current_user, params) }
  let(:order_date) { Date.parse("2022-05-26") }

  let(:report_table) do
    report.table_rows
  end

  context "viewing the report" do
    let!(:order) do
      create(
        :completed_order_with_totals,
        number: "R644360121",
        line_items_count: 1,
        user: customer.user,
        customer:,
        distributor:,
        completed_at: order_date,
      ).tap do |order|
        order.line_items[0].variant.supplier.update(name: "Apple Farmer")
        order.line_items[0].update(product_name: "Apples")
        order.line_items[0].variant.update(sku: "APP")
      end
    end
    let(:comparison_report) do
      Rails.root.join(report_file_name).read
    end
    let(:report_file_name) do
      "spec/fixtures/reports/orders_and_fulfillment/order_cycle_customer_totals_report.csv"
    end

    context 'csv format' do
      let(:params) { { report_format: 'csv', display_summary_row: false, q: search_params } }

      it "generates the report" do
        expect(report_table.length).to eq(1)

        expect(report.render_as(:csv)).to eq comparison_report
      end
    end

    it "has a line item row" do
      distributor_name_field = report_table.first[0]
      expect(distributor_name_field).to eq distributor.name

      customer_name_field = report_table.first[1]
      expect(customer_name_field).to eq order.bill_address.full_name
    end

    it 'includes the order number and date in item rows' do
      expect(report.rows.first.order_number).to eq order.number
      expect(report.rows.first.date).to eq order.completed_at.strftime("%F %T")
    end

    it 'includes the summary row' do
      expect(report.rows.second.quantity).to eq "TOTAL"
      expect(report.rows.second.date).to eq order.completed_at.strftime("%F %T")
    end

    context "shipment state" do
      # by default, shipment state is hidden, so make fields_to_hide empty for this test
      let(:params) { { q: search_params, fields_to_hide: [] } }

      it 'includes the shipment state' do
        expect(report.rows.first.shipment_state).to eq order.shipment_state
      end
    end

    describe "final weight volume column" do
      # related to https://github.com/openfoodfoundation/openfoodnetwork/issues/13270
      # not sure how we got DEPRECATION WARNING: Rails 7.0 has deprecated Enumerable.sum
      # but these scenarios might be related
      shared_examples "the report is successfully generated" do |test_case, type|
        it "if column final_weight_volume is #{test_case}" do
          order.line_items[0].update!(final_weight_volume: type)
          expect(report_table.length).to eq(2)
        end
      end

      it_behaves_like "the report is successfully generated", "nil", nil
      it_behaves_like "the report is successfully generated", "an empty value", ""
      it_behaves_like "the report is successfully generated", "a white space", " "
      it_behaves_like "the report is successfully generated", "a string", "kilograms"
    end
  end

  context "loading shipping methods" do
    let!(:shipping_method1) {
      create(:shipping_method, distributors: [distributor], name: "First")
    }
    let!(:shipping_method2) {
      create(:shipping_method, distributors: [distributor], name: "Second")
    }
    let!(:shipping_method3) {
      create(:shipping_method, distributors: [distributor], name: "Third")
    }
    let!(:order) do
      create(
        :completed_order_with_totals,
        line_items_count: 1, user: customer.user,
        customer:, distributor:,
        completed_at: order_date,
      )
    end

    before do
      order.shipments.each(&:refresh_rates)
      order.select_shipping_method(shipping_method2.id)
    end

    it "displays the correct shipping_method" do
      expect(report.rows.first.shipping).to eq shipping_method2.name
    end
  end

  context "displaying payment fees" do
    context "with both failed and completed payments present" do
      let!(:order) {
        create(
          :order_ready_to_ship,
          user: customer.user,
          customer:, distributor:,
          completed_at: order_date,
        )
      }
      let(:completed_payment) { order.payments.completed.first }
      let!(:failed_payment) { create(:payment, order:, state: "failed") }

      before do
        completed_payment.adjustment.update amount: 123.00
        failed_payment.adjustment.update amount: 456.00, eligible: false, state: "finalized"
      end

      it "shows the correct payment fee amount for the order" do
        expect(report.rows.last.pay_fee_price).to eq completed_payment.adjustment.amount
      end
    end
  end

  context 'when a variant override applies', feature: :inventory do
    let!(:order) do
      create(
        :completed_order_with_totals,
        line_items_count: 1, user: customer.user,
        customer:, distributor:,
        completed_at: order_date,
      )
    end
    let(:overidden_sku) { 'magical_sku' }

    before do
      create(
        :variant_override,
        hub: distributor,
        variant: order.line_items.first.variant,
        sku: overidden_sku
      )
    end

    it 'uses the sku from the variant override' do
      expect(report.rows.first.sku).to eq overidden_sku
    end
  end

  describe '#default_params' do
    it 'should return expected expected_params' do
      expected_params = {
        fields_to_hide: %i[
          final_weight_volume
          voucher_label
          voucher_amount
          shipment_state
        ],
        q: {
          completed_at_gt: 1.month.ago.beginning_of_day,
          completed_at_lt: 1.day.from_now.beginning_of_day
        }
      }

      expect(report.default_params).to eq(expected_params)
    end
  end
end
