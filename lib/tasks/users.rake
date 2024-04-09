# frozen_string_literal: true

require 'csv'

namespace :ofn do
  desc 'remove the limit of enterprises a user can create'
  task :remove_enterprise_limit, [:user_id] => :environment do |_task, args|
    max_integer = 2_147_483_647
    user = Spree::User.find(args.user_id)
    user.update_attribute(:enterprise_limit, max_integer)
  end
end
