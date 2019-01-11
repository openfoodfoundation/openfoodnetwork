require 'spec_helper'

describe DefaultStockLocation do
  describe '.create!' do
    it "names the location 'OFN default'" do
      stock_location = described_class.create!
      expect(stock_location.name).to eq('OFN default')
    end

    it 'sets the location in the default country' do
      default_country = Spree::Country.find_by_iso(ENV['DEFAULT_COUNTRY_CODE'])
      stock_location = described_class.create!
      expect(stock_location.country).to eq(default_country)
    end

    it 'sets the first state in the country' do
      default_country = Spree::Country.find_by_iso(ENV['DEFAULT_COUNTRY_CODE'])
      stock_location = described_class.create!
      expect(stock_location.state).to eq(default_country.states.first)
    end
  end

  describe '.destroy_all' do
    it "removes all stock locations named 'OFN default'" do
      create(:stock_location, name: 'OFN default')
      create(:stock_location, name: 'OFN default')

      expect { described_class.destroy_all }
        .to change { Spree::StockLocation.count }.from(2).to(0)
    end
  end
end
