# frozen_string_literal: true

namespace :ofn do
  namespace :data do
    desc 'Checking missing required ids in Spree::StockMovement'
    task check_missing_required_missing_ids_in_spree_stock_movements: :environment do
      puts 'Checking for null stock_item_id'
      ids = Spree::StockMovement.where(stock_item_id: nil).pluck(:id)

      if ids.empty?
        puts 'No NULL stock_item_id found in spree_stock_movements'
      else
        puts 'NULL stock_item_ids s have been found in spree_stock_movements:'
        print ids
      end

      puts 'Checking for null quantity'
      ids = Spree::StockMovement.where(quantity: nil).pluck(:id)

      if ids.empty?
        puts 'No NULL quantity found in spree_stock_movements'
      else
        puts 'NULL quantity s have been found in spree_stock_movements:'
        print ids
      end
    end
  end
end
