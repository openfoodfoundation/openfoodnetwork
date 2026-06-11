# frozen_string_literal: true

RSpec.describe Admin::ProductsHelper do
  describe '#unit_value_with_description' do
    let(:variant) {
      create(:variant, variant_unit_scale: 1000.0, unit_value: 2000.0, unit_description: 'kg')
    }

    context 'when unit_value and unit_description are present' do
      it 'returns the scaled unit value with the description' do
        expect(helper.unit_value_with_description(variant)).to eq('2 kg')
      end
    end

    context 'when unit_value is nil' do
      before { variant.update_column(:unit_value, nil) }

      it 'returns the description' do
        expect(helper.unit_value_with_description(variant)).to eq('kg')
      end
    end

    context 'when unit_description is nil' do
      before { variant.update_column(:unit_description, nil) }

      it 'returns only the scaled unit value' do
        expect(helper.unit_value_with_description(variant)).to eq('2')
      end
    end

    context 'when variant_unit_scale is nil' do
      before { variant.update_column(:variant_unit_scale, nil) }

      it 'uses default scale of 1 and returns the unscaled unit value with the description' do
        expect(helper.unit_value_with_description(variant)).to eq('2000 kg')
      end
    end

    context 'when both unit_value and unit_description are nil' do
      before { variant.update_columns(unit_description: nil, unit_value: nil) }

      it 'returns empty string' do
        expect(helper.unit_value_with_description(variant)).to eq('')
      end
    end
  end

  describe '#prepare_new_variant' do
    let(:zone) { create(:zone_with_member) }
    let(:taxon) { create(:taxon) }
    let(:supplier) { create(:supplier_enterprise) }
    let(:product) {
      create(:taxed_product, zone:, price: 12.54, tax_rate_amount: 0,
                             included_in_price: true)
    }

    before do
      product.variants.last.update!(
        primary_taxon: taxon,
        supplier:,
        variant_unit: "weight",
        variant_unit_scale: 1000.0,
        unit_value: 1000.0,
        price: 9.99,
      )
    end

    it 'copies tax category from the last variant' do
      expect(helper.prepare_new_variant(product).tax_category_id)
        .to eq(product.variants.last.tax_category_id)
    end

    it 'copies category (primary taxon) from the last variant' do
      expect(helper.prepare_new_variant(product).primary_taxon_id).to eq(taxon.id)
    end

    it 'copies unit type from the last variant' do
      new_variant = helper.prepare_new_variant(product)
      expect(new_variant.variant_unit).to eq("weight")
      expect(new_variant.variant_unit_scale).to eq(1000.0)
    end

    it 'copies unit value from the last variant so the unit field renders non-empty' do
      expect(helper.prepare_new_variant(product).unit_value).to eq(1000.0)
    end

    it 'copies price from the last variant' do
      expect(helper.prepare_new_variant(product).price).to eq(9.99)
    end

    it 'copies producer (supplier) from the last variant' do
      expect(helper.prepare_new_variant(product).supplier_id).to eq(supplier.id)
    end

    it 'sets on_hand_desired to 0' do
      expect(helper.prepare_new_variant(product).on_hand_desired).to eq(0)
    end

    it 'does not copy on_demand, so new variants default to out of stock' do
      expect(helper.prepare_new_variant(product).on_demand_desired).to be_falsey
    end

    it 'overrides producer with an explicit integer producer_id' do
      other_supplier = create(:supplier_enterprise)
      expect(helper.prepare_new_variant(product, other_supplier.id).supplier_id)
        .to eq(other_supplier.id)
    end

    context 'when the product has no existing variants' do
      let(:product) { create(:product) }

      before { product.variants.destroy_all }

      it 'returns a variant with only supplier_id set' do
        new_variant = helper.prepare_new_variant(product, supplier.id)
        expect(new_variant.supplier_id).to eq(supplier.id)
        expect(new_variant.primary_taxon_id).to be_nil
      end
    end
  end
end
