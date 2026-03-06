# frozen_string_literal: true

class AddCustomerCreditPaymentMethod < ActiveRecord::Migration[7.1]
  def up
    # Create payment method
    execute(<<~SQL.squish
      INSERT INTO spree_payment_methods ( type, environment, active, display_on, created_at, updated_at)
      VALUES ('Spree::PaymentMethod::CustomerCredit', '#{Rails.env}', true, 'both', NOW(), NOW())
    SQL
           )
  end

  def down
    execute(<<~SQL.squish
      DELETE FROM spree_payment_methods WHERE type = 'Spree::PaymentMethod::CustomerCredit'
    SQL
           )
  end
end
