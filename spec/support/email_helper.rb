module OpenFoodNetwork
  module EmailHelper
    # Some specs trigger actions that send emails, for example creating an order.
    # But sending emails doesn't work out-of-the-box. This code sets it up.
    # It's here in a single place to allow an easy upgrade to Spree 2 which
    # needs a different implementation of this method.
    def setup_email
      create(:mail_method)
    end
  end
end
