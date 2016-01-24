class AddOnDemandAndSkuToVariantOverrides < ActiveRecord::Migration
  def change
    add_column :variant_overrides, :sku, :string, :default => nil, :after => :hub_id
    add_column :variant_overrides, :on_demand, :boolean, :default => nil, :after => :count_on_hand
  end
end
