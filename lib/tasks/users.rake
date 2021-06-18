# frozen_string_literal: true

require 'csv'

namespace :ofn do
  desc 'remove the limit of enterprises a user can create'
  task :remove_enterprise_limit, [:user_id] => :environment do |_task, args|
    RemoveEnterpriseLimit.new(args.user_id).call
  end

  class RemoveEnterpriseLimit
    MAX_INTEGER = 2_147_483_647

    def initialize(user_id)
      @user_id = user_id
    end

    def call
      user = Spree::User.find(user_id)
      user.update_attribute(:enterprise_limit, MAX_INTEGER)
    end

    private

    attr_reader :user_id
  end
end
