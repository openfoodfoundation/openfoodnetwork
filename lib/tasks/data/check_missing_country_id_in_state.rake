# frozen_string_literal: true

namespace :ofn do
  namespace :data do
    desc 'Checking missing country_id in Spree::State'
    task check_missing_country_id_in_spree_states: :environment do
      puts 'Checking for null country_id'
      ids = Spree::State.where(country_id: nil).pluck(:id)

      if ids.empty?
        puts 'No NULL country_id found in spree_states'
      else
        puts 'NULL country_ids s have been found in spree_states:'
        print ids
      end
    end
  end
end
