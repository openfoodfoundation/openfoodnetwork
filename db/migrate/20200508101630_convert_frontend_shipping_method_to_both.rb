# frozen_string_literal: true

class ConvertFrontendShippingMethodToBoth < ActiveRecord::Migration[4.2]
  def up
    # The display_on value front_end is not working
    #   (it's not being used in the back office to ignore shipping methods marked as front_end)
    # So, here we are converting all entries to the more generic "both" option
    #   both is represented as nil in the database
    # # This enables us to remove the front_end option from the code
    execute("UPDATE spree_shipping_methods SET display_on = null WHERE display_on = 'front_end'")
  end
end
