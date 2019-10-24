require 'csv'

namespace :ofn do
  desc 'remove the limit of enterprises a user can create'
  task :remove_enterprise_limit, [:user_id] => :environment do |_task, args|
    RemoveEnterpriseLimit.new(args.user_id).call
  end

  class RemoveEnterpriseLimit
    # rubocop:disable Style/NumericLiterals
    MAX_INTEGER = 2147483647
    # rubocop:enable Style/NumericLiterals

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
