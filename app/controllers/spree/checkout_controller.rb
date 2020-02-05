module Spree
  class CheckoutController < Spree::StoreController
    def edit
      flash.keep
      redirect_to main_app.checkout_path
    end
  end
end
