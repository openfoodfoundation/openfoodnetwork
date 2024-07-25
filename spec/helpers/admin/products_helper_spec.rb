# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::ProductsHelper do
  describe '#unit_value_with_description' do
    let(:product) { create(:product, variant_unit_scale: 1000.0) }
    let(:variant) { create(:variant, product:, unit_value: 2000.0, unit_description: 'kg') }

    context 'when unit_value and unit_description are present' do
      it 'returns the scaled unit value with the description' do
        expect(helper.unit_value_with_description(variant)).to eq('2 kg')
      end
    end

    context 'when unit_value is nil' do
      before { variant.update_column(:unit_value, nil) }

      it 'defaults to 1 and returns the scaled unit value with the description' do
        expect(helper.unit_value_with_description(variant)).to eq('0.001 kg')
      end
    end

    context 'when unit_description is nil' do
      before { variant.update_column(:unit_description, nil) }

      it 'returns only the scaled unit value' do
        expect(helper.unit_value_with_description(variant)).to eq('2')
      end
    end

    context 'when variant_unit_scale is nil' do
      before { product.update_column(:variant_unit_scale, nil) }

      it 'uses default scale of 1 and returns the unscaled unit value with the description' do
        expect(helper.unit_value_with_description(variant)).to eq('2000 kg')
      end
    end

    context 'when both unit_value and unit_description are nil' do
      before { variant.update_columns(unit_description: nil, unit_value: nil) }

      it 'returns the default unit value without description' do
        expect(helper.unit_value_with_description(variant)).to eq('0.001')
      end
    end
  end
end
