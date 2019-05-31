require 'spec_helper'

describe Spree::StockItem do
  let!(:variant) { create(:variant) }

  it 'refreshes the products cache on save' do
    expect(OpenFoodNetwork::ProductsCache).to receive(:variant_changed).with(variant)
    variant.on_hand = -2
  end
end
