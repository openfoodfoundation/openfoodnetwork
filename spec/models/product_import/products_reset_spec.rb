require 'spec_helper'

describe ProductImport::ProductsReset do
  let(:products_reset) { described_class.new(excluded_items_ids) }

  describe '#<<' do
    let(:excluded_items_ids) { [] }
    let(:supplier_ids) { 1 }

    it 'stores the specified supplier_ids' do
      products_reset << supplier_ids
      expect(products_reset.supplier_ids).to eq([supplier_ids])
    end
  end

  describe '#reset' do
    let(:supplier_ids) { enterprise.id }
    let(:enterprise) { variant.product.supplier }
    let(:variant) { create(:variant, count_on_hand: 2) }

    before { products_reset << supplier_ids }

    context 'when there are excluded_items_ids' do
      let(:excluded_items_ids) { [variant.id] }

      it 'does not update the count_on_hand of the excluded items' do
        products_reset.reset
        expect(variant.reload.count_on_hand).to eq(2)
      end

      it 'updates the count_on_hand of the non-excluded items' do
        non_excluded_variant = create(
          :variant,
          count_on_hand: 3,
          product: variant.product
        )
        products_reset.reset
        expect(non_excluded_variant.reload.count_on_hand).to eq(0)
      end
    end

    context 'when there are no excluded_items_ids' do
      let(:excluded_items_ids) { [] }

      it 'sets all count_on_hand to 0' do
        products_reset.reset
        expect(variant.reload.count_on_hand).to eq(0)
      end
    end

    context 'when excluded_items_ids is nil' do
      let(:excluded_items_ids) { nil }

      it 'sets all count_on_hand to 0' do
        products_reset.reset
        expect(variant.reload.count_on_hand).to eq(0)
      end
    end
  end
end
