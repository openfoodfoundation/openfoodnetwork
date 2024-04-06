# frozen_string_literal: true

require 'csv'

namespace :ofn do
  desc 'remove the limit of enterprises a user can create'
  task :remove_enterprise_limit, [:user_id] => :environment do |_task, args|
    require 'tasks/user/remove_enterprise_limit'
    RemoveEnterpriseLimit.new(args.user_id).call
  end
end
