# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Reporting::Reports::SalesTax::SalesTaxTotalsByOrder" do
  subject(:report) { Reporting::Reports::SalesTax::SalesTaxTotalsByOrder.new(user, {}) }

  let(:user) { create(:user) }
  let(:state_zone) { create(:zone_with_state_member) }
  let(:country_zone) { create(:zone_with_member) }
  let(:tax_category) { create(:tax_category, name: 'GST Food') }
  let!(:state_tax_rate) do
    create(:tax_rate, zone: state_zone, tax_category:, name: 'State', amount: 0.02)
  end
  let!(:country_tax_rate) do
    create(:tax_rate, zone: country_zone, tax_category:, name: 'Country', amount: 0.01)
  end
  let(:ship_address) do
    create(:ship_address, state: state_zone.members.first.zoneable,
                          country: country_zone.members.first.zoneable)
  end
  let(:variant) { create(:variant, tax_category: ) }
  let(:product) { variant.product }
  let(:supplier) do
    create(:supplier_enterprise, name: 'SupplierEnterprise', charges_sales_tax: true)
  end
  let(:distributor) do
    create(
      :distributor_enterprise_with_tax,
      name: 'DistributorEnterpriseWithTax',
      charges_sales_tax: true
    ).tap do |distributor|
      distributor.shipping_methods << shipping_method
      distributor.payment_methods << payment_method
    end
  end
  let(:payment_method) { create(:payment_method, :flat_rate) }
  let(:shipping_method) do
    create(:shipping_method, :flat_rate, amount: 10, tax_category_id: tax_category.id)
  end
  let(:order) { create(:order_with_distributor, distributor:) }
  let(:order_cycle) do
    create(:simple_order_cycle, name: 'oc1', suppliers: [supplier], distributors: [distributor],
                                variants: [variant])
  end
  let(:customer1) do
    create(:customer, enterprise: create(:enterprise), user: create(:user),
                      first_name: 'cfname', last_name: 'clname', code: 'ABC123')
  end
  let(:query_row) do
    [
      [state_tax_rate.id, order.id],
      order
    ]
  end

  before do
    variant.update!(supplier: )

    order.update!(
      number: 'ORDER_NUMBER_1',
      order_cycle_id: order_cycle.id,
      ship_address_id: ship_address.id,
      customer_id: customer1.id,
      email: 'order1@example.com'
    )
    order.line_items.create(variant:, quantity: 1, price: 100)

    # the enterprise fees can be known only when the user selects the variants
    # we'll need to create them by calling recreate_all_fees!
    order.recreate_all_fees!
  end

  describe "#filtered_tax_rate_total" do
    let(:query_row) do
      [
        [country_tax_rate.id, order.id],
        order
      ]
    end

    it "returns tax amount filtered by tax rate in query_row" do
      Orders::WorkflowService.new(order).complete!
      mock_voucher_adjustment_service

      filtered_tax_total = report.filtered_tax_rate_total(query_row)

      expect(filtered_tax_total).not_to eq(order.total_tax)

      # 10 % of 10.00 shipment cost + 10 % of 100.00 line item price
      expect(filtered_tax_total).to eq(0.1 + 1)
    end
  end

  describe "#tax_rate_total" do
    it "returns the tax amount filtered by tax rate in the query_row" do
      Orders::WorkflowService.new(order).complete!
      mock_voucher_adjustment_service

      tax_total = report.tax_rate_total(query_row)

      expect(tax_total).not_to eq(order.total_tax)

      # 20 % of 10.00 shipment cost + 20 % of 100.00 line item price
      expect(tax_total).to eq(0.2 + 2)
    end

    context "with a voucher" do
      let(:voucher) do
        create(:voucher_flat_rate, code: 'some_code', enterprise: order.distributor, amount: 10)
      end

      it "returns the tax amount adjusted with voucher tax discount" do
        add_voucher(order, voucher)
        mock_voucher_adjustment_service(excluded_tax: -0.29)

        tax_total = report.tax_rate_total(query_row)

        # 20 % of 10.00 shipment cost + 20 % of 100.00 line item price - voucher tax
        expect(tax_total).to eq(0.2 + 2 - 0.29)
      end
    end
  end

  describe "#total_excl_tax" do
    it "returns the total excluding tax specified in query_row" do
      Orders::WorkflowService.new(order).complete!
      mock_voucher_adjustment_service

      total = report.total_excl_tax(query_row)

      # order.total - order.total_tax
      expect(total).to eq(113.3 - 3.3)
    end

    context "with a voucher" do
      let(:voucher) do
        create(:voucher_flat_rate, code: 'some_code', enterprise: order.distributor, amount: 10)
      end

      it "returns the total exluding tax and indcluding voucher tax discount" do
        add_voucher(order, voucher)
        mock_voucher_adjustment_service(excluded_tax: -0.29)

        total = report.total_excl_tax(query_row)

        # discounted order total - discounted order tax
        # (113.3 - 10) - (3.3 - 0.29)
        expect(total).to eq 100.29
      end
    end
  end

  describe "#total_incl_tax" do
    it "returns the total including the tax specified in query_row" do
      Orders::WorkflowService.new(order).complete!
      mock_voucher_adjustment_service

      total = report.total_incl_tax(query_row)

      # order.total - order.total_tax + filtered tax
      expect(total).to eq(113.3 - 3.3 + 2.2)
    end
  end

  describe "#rules" do
    before do
      Orders::WorkflowService.new(order).complete!
    end

    it "returns rules" do
      mock_voucher_adjustment_service

      expected_rules = [
        {
          group_by: :distributor,
        },
        {
          group_by: :order_cycle,
        },
        {
          group_by: :order_number,
          summary_row: an_instance_of(Proc)
        }
      ]

      expect(report.rules).to match(expected_rules)
    end

    describe "summary_row" do
      it "returns expected totals" do
        mock_voucher_adjustment_service

        rules = report.rules

        # Running the "summary row" Proc
        item = [[state_tax_rate.id, order.id], order]
        summary_row = rules.third[:summary_row].call(nil, [item], nil)

        expect(summary_row).to eq(
          {
            total_excl_tax: 110.00,
            tax: 3.3,
            total_incl_tax: 113.30,
            first_name: "cfname",
            last_name: "clname",
            code: "ABC123",
            email: "order1@example.com"
          }
        )
      end

      context "with a voucher" do
        let(:voucher) do
          create(:voucher_flat_rate, code: 'some_code', enterprise: order.distributor, amount: 10)
        end

        it "adjusts total_excl_tax and tax with voucher tax" do
          add_voucher(order, voucher)
          mock_voucher_adjustment_service(excluded_tax: -0.29)

          # total_excl_tax = order.total - (order.total_tax - voucher_tax)
          # tax = order.total_tax - voucher_tax
          expected_summary = {
            total_excl_tax: 100.29,
            tax: 3.01,
            total_incl_tax: 103.30,
            first_name: "cfname",
            last_name: "clname",
            code: "ABC123",
            email: "order1@example.com"
          }

          rules = report.rules

          # Running the "summary row" Proc
          item = [[state_tax_rate.id, order.id], order]
          summary_row = rules.third[:summary_row].call(nil, [item], nil)

          expect(summary_row).to eq(expected_summary)
        end
      end
    end
  end

  describe "#voucher_tax_adjustment" do
    context "with tax excluded from price" do
      it "returns the tax related voucher adjustment" do
        mock_voucher_adjustment_service(excluded_tax: -0.1)

        expect(report.voucher_tax_adjustment(order)).to eq(-0.1)
      end
    end

    context "with tax included in price" do
      it "returns the tax part of the voucher adjustment" do
        mock_voucher_adjustment_service(included_tax: -0.2)

        expect(report.voucher_tax_adjustment(order)).to eq(-0.2)
      end
    end

    context "with both type of tax" do
      it "returns sum of the tax part of voucher adjustment and tax related voucher adjusment" do
        mock_voucher_adjustment_service(included_tax: -0.5, excluded_tax: -0.1)

        expect(report.voucher_tax_adjustment(order)).to eq(-0.6)
      end
    end
  end

  def add_voucher(order, voucher)
    # Add voucher to the order
    voucher.create_adjustment(voucher.code, order)
    VoucherAdjustmentsService.new(order).update
    order.update_totals_and_states

    Orders::WorkflowService.new(order).complete!
  end

  def mock_voucher_adjustment_service(included_tax: 0.0, excluded_tax: 0.0)
    service = instance_double(
      VoucherAdjustmentsService,
      voucher_included_tax: included_tax,
      voucher_excluded_tax: excluded_tax
    )

    allow(VoucherAdjustmentsService).to receive(:new).and_return(service)
  end
end
