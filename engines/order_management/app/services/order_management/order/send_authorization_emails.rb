# frozen_string_literal: true

module OrderManagement
  module Order
    module SendAuthorizationEmails
      def call!(redirect_url = full_order_path(@order))
        super(redirect_url)

        return unless @payment.requires_authorization?

        PaymentMailer.authorize_payment(@payment).deliver_now
        PaymentMailer.authorization_required(@payment).deliver_now
      end
    end
  end
end
