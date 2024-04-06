# frozen_string_literal: true

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
