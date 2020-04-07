require 'spec_helper'
require 'open_food_network/reports/variant_overrides'

module OpenFoodNetwork::Reports
  describe VariantOverrides do
    subject(:variant_overrides) { described_class.new(order.line_items) }

    let(:distributor) { create(:distributor_enterprise) }
    let(:order) do
      create(:completed_order_with_totals, line_items_count: 1,
              distributor: distributor)
    end
    let(:variant) { order.line_items.first.variant }
    let!(:variant_override) do
      create(
        :variant_override,
        hub: distributor,
        variant: variant,
      )
    end

    describe '#indexed' do
      let(:result) { variant_overrides.indexed }

      it 'indexes variant override mappings by distributor id' do
        expect(variant_overrides.indexed).to eq(
          distributor.id => { variant => variant_override }
        )
      end
    end
  end
end
