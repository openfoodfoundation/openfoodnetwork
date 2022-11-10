# frozen_string_literal: true

require 'spec_helper'

describe DefaultStockLocation do
  describe '.find_or_create' do
    context 'when a location named default already exists' do
      let!(:location) do
        country = create(:country)
        state = Spree::State.create(name: 'Alabama', country: country)
        Spree::StockLocation.create!(
          name: 'default',
          country_id: country.id,
          state_id: state.id
        )
      end

      it 'returns the location' do
        expect(described_class.find_or_create).to eq(location)
      end

      it 'does not create any other location' do
        expect { described_class.find_or_create }.not_to change(Spree::StockLocation, :count)
      end
    end

    context 'when a location named default does not exist' do
      it 'returns the location' do
        location = described_class.find_or_create
        expect(location.name).to eq('default')
      end

      it 'does not create any other location' do
        expect { described_class.find_or_create }
          .to change(Spree::StockLocation, :count).from(0).to(1)
      end
    end
  end
end
