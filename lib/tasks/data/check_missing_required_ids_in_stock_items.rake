# frozen_string_literal: true

namespace :ofn do
  namespace :data do
    desc 'Checking missing required ids in Spree::StockItem'
    task check_missing_required_missing_ids_in_spree_stock_items: :environment do
      puts 'Checking for null stock_location_id'
      ids = Spree::StockItem.where(stock_location_id: nil).pluck(:id)

      if ids.empty?
        puts 'No NULL stock_location_id found in spree_stock_items'
      else
        puts 'NULL stock_location_ids s have been found in spree_stock_items:'
        print ids
      end

      puts 'Checking for null variant_id'
      ids = Spree::StockItem.where(variant_id: nil).pluck(:id)

      if ids.empty?
        puts 'No NULL variant_id found in spree_stock_items'
      else
        puts 'NULL variant_ids s have been found in spree_stock_items:'
        print ids
      end
    end
  end
end
