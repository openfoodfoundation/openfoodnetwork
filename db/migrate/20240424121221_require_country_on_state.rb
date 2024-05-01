# frozen_string_literal: true

class RequireCountryOnState < ActiveRecord::Migration[7.0]
  def change
    change_column_null :spree_states, :country_id, false
  end
end
