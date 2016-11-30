class AddPriceEstimateToStandingLineItems < ActiveRecord::Migration
  def change
    add_column :standing_line_items, :price_estimate, :decimal, :precision => 8,  :scale => 2
  end
end
