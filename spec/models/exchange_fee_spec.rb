require 'spec_helper'

describe ExchangeFee do
  describe "products caching" do
    let(:exchange) { create(:exchange) }
    let(:enterprise_fee) { create(:enterprise_fee) }

    it "refreshes the products cache on change" do
      expect(OpenFoodNetwork::ProductsCache).to receive(:exchange_changed).with(exchange)
      exchange.enterprise_fees << enterprise_fee
    end

    it "refreshes the products cache on destruction" do
      exchange.enterprise_fees << enterprise_fee
      expect(OpenFoodNetwork::ProductsCache).to receive(:exchange_changed).with(exchange)
      exchange.reload.exchange_fees.destroy_all
    end
  end
end
