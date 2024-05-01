# frozen_string_literal: true

namespace :ofn do
  namespace :data do
    desc 'Checking missing property_id in ProductProperty'
    task check_missing_property_in_joint_table_product_property: :environment do
      puts 'Checking for null property_id'
      ids = Spree::ProductProperty.where(property_id: nil).pluck(:id)

      if ids.empty?
        puts 'No NULL property_id found in spree_product_properties'
      else
        puts 'NULL property_ids s have been found in spree_product_properties:'
        print ids
      end
    end
  end
end
