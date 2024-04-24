# frozen_string_literal: true

namespace :ofn do
  namespace :data do
    desc 'Checking order_id in ReturnAuthorization'
    task check_missing_order_id_in_return_authorizations: :environment do
      puts 'Checking for null order_id'
      ids = Spree::ReturnAuthorization.where(order_id: nil).pluck(:id)

      if ids.empty?
        puts 'No NULL order_id found in spree_return_authorizations'
      else
        puts 'NULL order_id s have been found in spree_return_authorizations:'
        print ids
      end
    end
  end
end
