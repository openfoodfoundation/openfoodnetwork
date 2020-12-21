# frozen_string_literal: true

require 'spec_helper'

describe DefaultShippingCategory do
  describe '.create!' do
    it "names the location 'Default'" do
      shipping_category = described_class.create!
      expect(shipping_category.name).to eq 'Default'
    end
  end

  describe 'find_or_create' do
    context 'when a Default category already exists' do
      let!(:category) do
        Spree::ShippingCategory.create!(name: 'Default')
      end

      it 'returns the category' do
        expect(described_class.find_or_create).to eq category
      end

      it 'does not create another category' do
        expect { described_class.find_or_create }.not_to change(Spree::ShippingCategory, :count)
      end
    end

    context 'when a Default category does not exist' do
      it 'returns the category' do
        category = described_class.find_or_create
        expect(category.name).to eq 'Default'
      end

      it 'does not create another category' do
        expect { described_class.find_or_create }
          .to change(Spree::ShippingCategory, :count).from(0).to(1)
      end
    end
  end
end
