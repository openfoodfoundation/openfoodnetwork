# frozen_string_literal: true

class AddUniqueIndexEmailEntrepriseToCustomers < ActiveRecord::Migration[7.0]
  def change
    remove_index :customers, :email, name: :index_customers_on_email
    add_index(:customers, [:email, :enterprise_id], unique: true)
  end
end
