require 'spec_helper'

describe DefaultStockLocation do
  describe '.create!' do
    it "names the location 'OFN default'" do
      stock_location = described_class.create!
      expect(stock_location.name).to eq('default')
    end

    it 'sets the location in the default country' do
      default_country = Spree::Country.find_by(iso: ENV['DEFAULT_COUNTRY_CODE'])
      stock_location = described_class.create!
      expect(stock_location.country).to eq(default_country)
    end

    it 'sets the first state in the country' do
      default_country = Spree::Country.find_by(iso: ENV['DEFAULT_COUNTRY_CODE'])
      stock_location = described_class.create!
      expect(stock_location.state).to eq(default_country.states.first)
    end
  end

  describe '.destroy_all' do
    it "removes all stock locations named 'default'" do
      create(:stock_location)

      expect { described_class.destroy_all }
        .to change { Spree::StockLocation.count }.to(0)
    end
  end

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
