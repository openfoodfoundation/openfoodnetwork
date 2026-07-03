# frozen_string_literal: true

RSpec.describe Reporting::Reports::BulkCoop::CustomerPayments do
  let(:user) { create(:admin_user) }

  describe '#query_result' do
    let(:params) { {} }
    let(:d1) { create(:distributor_enterprise) }
    let(:oc1) { create(:simple_order_cycle) }
    subject { described_class.new user, params }

    it 'returns results grouped by order without error' do
      product = create(:product, group_buy: true)
      order = create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1)
      li = build(:line_item_with_shipment, variant: product.variants.first)
      order.line_items << li

      result = subject.query_result
      expect(result.first).to include(li)
    end

    context "when bulk_coop_filters feature is disabled" do
      it 'includes orders with mixed bulk and non-bulk products' do
        bulk_product = create(:product, group_buy: true)
        non_bulk_product = create(:product, group_buy: false)
        order = create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1)
        bulk_li = build(:line_item_with_shipment, variant: bulk_product.variants.first)
        non_bulk_li = build(:line_item_with_shipment,
                            variant: non_bulk_product.variants.first)
        order.line_items << bulk_li
        order.line_items << non_bulk_li

        result = subject.query_result
        expect(result.length).to eq(1)
        expect(result.first).to include(bulk_li, non_bulk_li)
      end

      it 'includes orders with only non-bulk products' do
        non_bulk_product = create(:product, group_buy: false)
        order = create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1)
        non_bulk_li = build(:line_item_with_shipment,
                            variant: non_bulk_product.variants.first)
        order.line_items << non_bulk_li

        result = subject.query_result
        expect(result.length).to eq(1)
        expect(result.first).to include(non_bulk_li)
      end
    end

    context "when bulk_coop_filters feature is enabled", feature: :bulk_coop_filters do
      it 'excludes orders with only non-bulk products' do
        non_bulk_product = create(:product, group_buy: false)
        order = create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1)
        non_bulk_li = build(:line_item_with_shipment,
                            variant: non_bulk_product.variants.first)
        order.line_items << non_bulk_li

        expect(subject.query_result).to be_empty
      end

      it 'includes all line items from orders that contain at least one bulk product' do
        bulk_product = create(:product, group_buy: true)
        non_bulk_product = create(:product, group_buy: false)
        order = create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1)
        bulk_li = build(:line_item_with_shipment, variant: bulk_product.variants.first)
        non_bulk_li = build(:line_item_with_shipment,
                            variant: non_bulk_product.variants.first)
        order.line_items << bulk_li
        order.line_items << non_bulk_li

        result = subject.query_result
        expect(result.length).to eq(1)
        expect(result.first).to include(bulk_li, non_bulk_li)
      end
    end
  end

  describe '#columns' do
    subject { described_class.new user }

    it 'returns' do
      expect(subject.columns.values).to match_array(
        [
          :order_billing_address_name,
          :order_completed_at,
          :customer_payments_total_cost,
          :customer_payments_amount_owed,
          :customer_payments_amount_paid,
        ]
      )
    end
  end

  # Yes, I know testing a private method is bad practice but report's design, tighly coupling
  # makes it very hard to make things testeable without ending up in a wormwhole.
  # This is a trade-off.
  describe '#customer_payments_amount_owed' do
    let(:user) { build(:user) }
    let(:order) { create(:order) }
    let!(:line_item) { create(:line_item, order:) }

    it 'calls #new_outstanding_balance' do
      expect_any_instance_of(Spree::Order).to receive(:new_outstanding_balance)
      described_class.new(user).__send__(:customer_payments_amount_owed, [line_item])
    end
  end
end
