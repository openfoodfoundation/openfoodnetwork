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
    let(:product) {
      create(:taxed_product, zone:, price: 12.54, tax_rate_amount: 0,
                             included_in_price: true)
    }

    context 'when tax category is present for first varient' do
      it 'sets tax category for new variant' do
        first_variant_tax_id = product.variants.first.tax_category_id
        expect(helper.prepare_new_variant(product, []).tax_category_id).to eq(first_variant_tax_id)
      end
    end
  end
end
