require 'spec_helper'

describe ProductImport::InventoryReset do
  let(:inventory_reset) { described_class.new(excluded_items_ids) }

  describe '#<<' do
    let(:excluded_items_ids) { [] }
    let(:supplier_ids) { 1 }

    it 'stores the specified supplier_ids' do
      inventory_reset << supplier_ids
      expect(inventory_reset.supplier_ids).to eq([supplier_ids])
    end
  end

  describe '#reset' do
    let(:supplier_ids) { enterprise.id }
    let(:enterprise) { variant.product.supplier }
    let(:variant) { create(:variant) }

    let!(:variant_override) do
      create(
        :variant_override,
        count_on_hand: 10,
        hub: enterprise,
        variant: variant
      )
    end

    before { inventory_reset << supplier_ids }

    context 'when there are excluded_items_ids' do
      let(:excluded_items_ids) { [variant_override.id] }

      it 'does not update the count_on_hand of the excluded items' do
        inventory_reset.reset
        expect(variant_override.reload.count_on_hand).to eq(10)
      end

      it 'updates the count_on_hand of the non-excluded items' do
        non_excluded_variant_override = create(
          :variant_override,
          count_on_hand: 3,
          hub: enterprise,
          variant: variant
        )
        inventory_reset.reset
        expect(non_excluded_variant_override.reload.count_on_hand).to eq(0)
      end
    end

    context 'when there are no excluded_items_ids' do
      let(:excluded_items_ids) { [] }

      it 'sets all count_on_hand to 0' do
        inventory_reset.reset
        expect(variant_override.reload.count_on_hand).to eq(0)
      end
    end

    context 'when excluded_items_ids is nil' do
      let(:excluded_items_ids) { nil }

      it 'sets all count_on_hand to 0' do
        inventory_reset.reset
        expect(variant_override.reload.count_on_hand).to eq(0)
      end
    end
  end
end
