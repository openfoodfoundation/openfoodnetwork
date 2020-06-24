module OpenFoodNetwork
  module EmailHelper
    # Some specs trigger actions that send emails, for example creating an order.
    # But sending emails doesn't work out-of-the-box. This code sets it up.
    def setup_email
      Spree::Config[:mails_from] = "test@ofn.example.org"
    end

    # Ensures the value `perform_deliveries` had is restored. This saves us
    # from messing up with the test suite's global state which is cause of
    # trouble.
    def performing_deliveries
      old_value = ActionMailer::Base.perform_deliveries
      ActionMailer::Base.perform_deliveries = true

      yield

      ActionMailer::Base.perform_deliveries = old_value
    end
  end
end
