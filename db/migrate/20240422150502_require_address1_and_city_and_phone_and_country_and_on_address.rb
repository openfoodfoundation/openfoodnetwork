class RequireAddress1AndCityAndPhoneAndCountryAndOnAddress < ActiveRecord::Migration[7.0]
  def change
    change_column_null :spree_addresses, :address1, false
    change_column_null :spree_addresses, :city, false
    change_column_null :spree_addresses, :phone, false
    change_column_null :spree_addresses, :country_id, false
  end
end
