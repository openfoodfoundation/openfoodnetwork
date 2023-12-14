# frozen_string_literal: false

class Invoice
  class DataPresenter
    class ShippingMethod < Invoice::DataPresenter::Base
      attributes :id, :name, :require_ship_address
      invoice_generation_attributes :id

      def category
        I18n.t "invoice_shipping_category_#{require_ship_address ? 'delivery' : 'pickup'}"
      end
    end
  end
end
