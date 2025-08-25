# frozen_string_literal: true

class AddRedirectAuthUrlInPaymentModel < ActiveRecord::Migration[7.1]
  def change
    add_column :spree_payments, :redirect_auth_url, :string
  end
end
