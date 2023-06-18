# frozen_string_literal: false

class Invoice
  class DataPresenter
    class Payment < Invoice::DataPresenter::Base
      attributes :amount, :currency, :state, :payment_method_id
      attributes_with_presenter :payment_method
      invoice_generation_attributes :amount, :payment_method_id
      invoice_update_attributes :state

      def created_at
        datetime = data&.[](:created_at)
        datetime.present? ? Time.zone.parse(datetime) : nil
      end

      def display_amount
        Spree::Money.new(amount, currency: currency)
      end

      def payment_method_name
        payment_method&.name
      end
    end
  end
end
