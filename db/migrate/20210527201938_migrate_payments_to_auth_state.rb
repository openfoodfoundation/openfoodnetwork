class MigratePaymentsToAuthState < ActiveRecord::Migration[5.2]
  class Spree::Payment < ApplicationRecord
    scope :with_state, ->(s) { where(state: s.to_s) }
  end

  def change
    Spree::Payment.where.not(cvv_response_message: nil).with_state("pending").
      update_all(state: "requires_authorization")
  end
end
