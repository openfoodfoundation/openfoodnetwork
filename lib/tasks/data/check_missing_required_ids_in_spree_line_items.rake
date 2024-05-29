# frozen_string_literal: true

namespace :ofn do
  namespace :data do
    desc 'Checking missing required ids in Spree::LineItem'
    task check_missing_required_missing_ids_in_spree_line_items: :environment do
      puts 'Checking for null order_id'
      ids = Spree::LineItem.where(order_id: nil).pluck(:id)

      if ids.empty?
        puts 'No NULL order_id found in spree_line_items'
      else
        puts 'NULL order_ids s have been found in spree_line_items:'
        print ids
      end

      puts 'Checking for null variant_id'
      ids = Spree::LineItem.where(variant_id: nil).pluck(:id)

      if ids.empty?
        puts 'No NULL variant_id found in spree_line_items'
      else
        puts 'NULL variant_id s have been found in spree_line_items:'
        print ids
      end
    end
  end
end
