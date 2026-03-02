# frozen_string_literal: true

RSpec.describe Spree::Admin::TaxCategoriesHelper do
  describe '#tax_category_dropdown_options' do
    let!(:default_tax_category) { create(:tax_category, is_default: true) }
    let!(:other_tax_category) { create(:tax_category, is_default: false) }

    context 'when products require a tax category' do
      it 'returns include_blank as false' do
        options = helper.tax_category_dropdown_options(true)
        expect(options[:include_blank]).to eq(false)
      end

      it 'returns the default tax category as selected' do
        options = helper.tax_category_dropdown_options(true)
        expect(options[:selected]).to eq(default_tax_category.id)
      end

      context 'when no default tax category exists' do
        before { default_tax_category.update(is_default: false) }

        it 'returns nil for the selected value' do
          options = helper.tax_category_dropdown_options(true)
          expect(options[:selected]).to be_nil
        end
      end
    end

    context 'when products do not require a tax category' do
      it 'returns include_blank as the translated "none" string' do
        options = helper.tax_category_dropdown_options(false)
        expect(options[:include_blank]).to eq("None")
      end

      it 'does not include a selected tax category' do
        options = helper.tax_category_dropdown_options(false)
        expect(options[:selected]).to be_nil
      end
    end
  end
end
