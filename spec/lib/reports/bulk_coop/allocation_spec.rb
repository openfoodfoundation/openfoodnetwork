# frozen_string_literal: true

RSpec.describe Reporting::Reports::BulkCoop::Allocation do
  subject { described_class.new(user, {}) }

  let(:user) { create(:admin_user) }
  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:simple_order_cycle) }
  let(:order) { create(:order, completed_at: 1.day.ago, order_cycle:, distributor:) }

  describe '#query_result' do
    context 'when a customer orders multiple products in the same order' do
      let(:li1) { build(:line_item_with_shipment, variant: create(:variant)) }
      let(:li2) { build(:line_item_with_shipment, variant: create(:variant)) }

      before do
        order.line_items << li1
        order.line_items << li2
      end

      it 'returns one row per product, not one row per order' do
        expect(subject.query_result.length).to eq(2)
      end
    end
  end

  describe '#rows' do
    let(:variant) { create(:variant, display_name: "Pink Lady") }
    let(:line_item) { build(:line_item_with_shipment, variant:) }

    before { order.line_items << line_item }

    it 'uses the snapshotted variant name' do
      expect(subject.rows.first.variant).to eq(line_item.full_variant_name)
    end
  end
end
