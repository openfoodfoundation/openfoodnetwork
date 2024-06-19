# frozen_string_literal: true

class RequireOrderOnReturnAuthorization < ActiveRecord::Migration[7.0]
  def change
    change_column_null :spree_return_authorizations, :order_id, false
  end
end
