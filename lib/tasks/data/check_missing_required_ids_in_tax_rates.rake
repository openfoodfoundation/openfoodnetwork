# frozen_string_literal: true

namespace :ofn do
  namespace :data do
    desc 'Checking missing required ids in Spree::TaxRate'
    task check_missing_required_missing_ids_in_spree_tax_rates: :environment do
      puts 'Checking for null tax_category_id'
      ids = Spree::TaxRate.where(tax_category_id: nil).pluck(:id)

      if ids.empty?
        puts 'No NULL tax_category_id found in spree_tax_rates'
      else
        puts 'NULL tax_category_ids s have been found in spree_tax_rates:'
        print ids
      end
    end
  end
end
