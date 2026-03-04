# frozen_string_literal: true

class AddApiCustomerCreditPaymentMethod < ActiveRecord::Migration[7.1]
  def up
    # Create payment method
    execute(<<~SQL.squish
      INSERT INTO spree_payment_methods ( type, environment, active, display_on, created_at, updated_at)
      VALUES ('Spree::PaymentMethod::ApiCustomerCredit', '#{Rails.env}', true, 'back_end', NOW(), NOW())
    SQL
           )
  end

  def down
    execute(<<~SQL.squish
      DELETE FROM spree_payment_methods WHERE type = 'Spree::PaymentMethod::ApiCustomerCredit'
    SQL
           )
  end
end
