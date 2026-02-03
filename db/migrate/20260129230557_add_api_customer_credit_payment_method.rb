# frozen_string_literal: true

class AddApiCustomerCreditPaymentMethod < ActiveRecord::Migration[7.1]
  def up
    # Create payment method
    execute(<<-SQL.squish
      INSERT INTO spree_payment_methods ( type, name, description, environment, active, display_on, created_at, updated_at)
      VALUES ('Spree::PaymentMethod::Check', 'api_payment_method.name', 'api_payment_method.description', '#{Rails.env}', true, 'back_end', NOW(), NOW())
    SQL
           )

    # Link to existing hub
    execute(<<-SQL.squish
      INSERT INTO distributors_payment_methods (distributor_id, payment_method_id, created_at, updated_at)
      SELECT id, (SELECT id FROM spree_payment_methods WHERE name = 'api_payment_method.name') as payment_method_id, NOW() as created_at, NOW() as updated_at
      FROM enterprises WHERE sells != 'none'
    SQL
           )
  end

  def down
    execute(<<-SQL.squish
      DELETE FROM distributors_payment_methods
      WHERE payment_method_id = (SELECT id FROM spree_payment_methods WHERE name = 'api_payment_method.name')
    SQL
           )

    execute(<<-SQL.squish
      DELETE FROM spree_payment_methods WHERE name = 'api_payment_method.name'
    SQL
           )
  end
end
