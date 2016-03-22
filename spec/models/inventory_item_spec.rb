require 'spec_helper'
require 'open_food_network/products_cache'

describe InventoryItem do
  describe "caching" do
    let(:ii) { create(:inventory_item) }

    it "refreshes the products cache on save" do
      expect(OpenFoodNetwork::ProductsCache).to receive(:inventory_item_changed).with(ii)
      ii.visible = false
      ii.save
    end

    # Inventory items are not destroyed
  end
end
