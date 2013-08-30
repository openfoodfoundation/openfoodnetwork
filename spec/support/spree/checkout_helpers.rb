module Spree
  module CheckoutHelpers
    def click_checkout_continue_button
      page.find('#add_new_save_checkout_button input[type=submit]').click
    end
  end
end
