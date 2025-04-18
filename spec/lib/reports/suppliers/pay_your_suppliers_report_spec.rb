# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Pay Your Suppliers Report" do
  let(:hub) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:open_order_cycle, distributors: [hub]) }
  let(:product) { order.products.first }
  let(:variant) { product.variants.first }
  let(:supplier) { variant.supplier }
  let(:current_user) { hub.owner }
  let!(:order) do
    create(:completed_order_with_totals, distributor: hub, order_cycle:, line_items_count: 1)
  end
  let(:params) { { display_summary_row: true } }
  let(:report) { Reporting::Reports::Suppliers::Base.new(current_user, { q: params }) }
  let(:report_table_rows) { report.rows }

  context "without fees and taxes" do
    it "Generates the report" do
      expect(report_table_rows.length).to eq(1)
      table_row = report_table_rows.first

      expect(table_row.producer).to eq(supplier.name)
      expect(table_row.producer_address).to eq(supplier.address.full_address)
      expect(table_row.producer_abn_acn).to eq("none")
      expect(table_row.producer_charges_gst).to eq("No")
      expect(table_row.email).to eq("none")
      expect(table_row.hub).to eq(hub.name)
      expect(table_row.hub_address).to eq(hub.address.full_address)
      expect(table_row.hub_contact_email).to eq("none")
      expect(table_row.order_number).to eq(order.number)
      expect(table_row.order_date).to eq(order.completed_at.to_date.to_s)
      expect(table_row.order_cycle).to eq(order_cycle.name)
      expect(table_row.order_cycle_start_date).to eq(
        order_cycle.orders_open_at.to_date.to_s
      )
      expect(table_row.order_cycle_end_date).to eq(order_cycle.orders_close_at.to_date.to_s)
      expect(table_row.product).to eq(product.name)
      expect(table_row.variant_unit_name).to eq(variant.full_name)
      expect(table_row.quantity).to eq(1)
      expect(table_row.total_excl_fees_and_tax.to_f).to eq(10.0)
      expect(table_row.total_excl_vat.to_f).to eq(10.0)
      expect(table_row.total_fees_excl_tax.to_f).to eq(0.0)
      expect(table_row.total_tax_on_fees.to_f).to eq(0.0)
      expect(table_row.total_tax_on_product.to_f).to eq(0.0)
      expect(table_row.total_tax.to_f).to eq(0.0)
      expect(table_row.total.to_f).to eq(10.0)
    end
  end

  context "with taxes and fees" do
    let(:line_item) { order.line_items.first }
    let(:tax_rate) {
      create(
        :tax_rate,
        included_in_price: false,
        zone: create(:zone_with_member)
      )
    }
    let(:tax_category) {
      create(
        :tax_category,
        tax_rates: [tax_rate]
      )
    }
    let!(:enterprise_fee) do
      create(
        :enterprise_fee,
        enterprise: supplier,
        fee_type: 'sales',
        amount: 0.1,
        tax_category:
      )
    end

    before do
      # Prepare order or line_item to have respective tax adjustments
      hub.update!(charges_sales_tax: true)
      line_item.variant.update!(tax_category:)
      line_item.copy_tax_category

      exchange = order_cycle.exchanges.take
      exchange.enterprise_fees << enterprise_fee
      exchange.exchange_variants.build(variant: line_item.variant)
      exchange.incoming = true
      exchange.save!

      OpenFoodNetwork::EnterpriseFeeCalculator
        .new(hub, order_cycle)
        .create_line_item_adjustments_for(line_item)

      order.create_tax_charge!
    end

    context "supplier charges tax" do
      before do
        supplier.update!(charges_sales_tax: true)
      end

      context "added tax" do
        it "Generates the report" do
          expect(report_table_rows.length).to eq(1)
          table_row = report_table_rows.first

          expect(table_row.producer_charges_gst).to eq('Yes')
          expect(table_row.total_excl_fees_and_tax.to_f).to eq(10.0)
          expect(table_row.total_excl_vat.to_f).to eq(10.1)
          expect(table_row.total_fees_excl_tax.to_f).to eq(0.1)
          expect(table_row.total_tax_on_fees.to_f).to eq(0.01)
          expect(table_row.total_tax_on_product.to_f).to eq(1.0)
          expect(table_row.total_tax.to_f).to eq(1.01)
          expect(table_row.total.to_f).to eq(11.11)
        end
      end

      context "included tax" do
        before do
          tax_rate.update(included_in_price: true)
          order.create_tax_charge!
        end
        it "Generates the report" do
          expect(report_table_rows.length).to eq(1)
          table_row = report_table_rows.first

          expect(table_row.producer_charges_gst).to eq('Yes')
          expect(table_row.total_excl_fees_and_tax.to_f).to eq(9.09)
          expect(table_row.total_excl_vat.to_f).to eq(9.18)
          expect(table_row.total_fees_excl_tax.to_f).to eq(0.09)
          expect(table_row.total_tax_on_fees.to_f).to eq(0.01)
          expect(table_row.total_tax_on_product.to_f).to eq(0.91)
          expect(table_row.total_tax.to_f).to eq(0.92)
          expect(table_row.total.to_f).to eq(10.10)
        end
      end
    end

    context "supplier does not charge tax" do
      before do
        supplier.update!(charges_sales_tax: false)
      end
      it "Generates the report, without displaying taxes" do
        expect(report_table_rows.length).to eq(1)
        table_row = report_table_rows.first

        expect(table_row.producer_charges_gst).to eq('No')
        expect(table_row.total_excl_fees_and_tax.to_f).to eq(10.0)
        expect(table_row.total_excl_vat.to_f).to eq(10.1)
        expect(table_row.total_fees_excl_tax.to_f).to eq(0.1)
        expect(table_row.total_tax_on_fees.to_f).to eq(0.00)
        expect(table_row.total_tax_on_product.to_f).to eq(0.0)
        expect(table_row.total_tax.to_f).to eq(0.00)
        expect(table_row.total.to_f).to eq(10.1)
      end
    end

    context "fee is owned by the hub" do
      before do
        enterprise_fee.update(enterprise: hub)
        order.create_tax_charge!
      end

      it "Generates the report, without displaying enterprise fees" do
        # enterprise fee exists on the order
        fee = Spree::Adjustment.where(originator_type: "EnterpriseFee")[0]
        expect(fee.amount.to_f).to eq(0.1)

        # but is not displayed on the report
        expect(report_table_rows.length).to eq(1)
        table_row = report_table_rows.first

        expect(table_row.producer_charges_gst).to eq('No')
        expect(table_row.total_excl_fees_and_tax.to_f).to eq(10.0)
        expect(table_row.total_excl_vat.to_f).to eq(10.0)
        expect(table_row.total_fees_excl_tax.to_f).to eq(0.0)
        expect(table_row.total_tax_on_fees.to_f).to eq(0.00)
        expect(table_row.total_tax_on_product.to_f).to eq(0.0)
        expect(table_row.total_tax.to_f).to eq(0.00)
        expect(table_row.total.to_f).to eq(10.0)
      end
    end
  end
end
