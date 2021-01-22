# frozen_string_literal: true

# This controller (and respective route in the Spree engine)
#   is only needed for the spree_paypal_express gem that redirects here explicitly.
#
# According to the rails docs it would be possible to redirect
#   to CheckoutController directly in the routes
#   with a slash like "to: '/checkout#edit'", but it does not work in this case.
module Spree
  class CheckoutController < ::BaseController
    def edit
      flash.keep
      redirect_to main_app.checkout_path
    end
  end
end
