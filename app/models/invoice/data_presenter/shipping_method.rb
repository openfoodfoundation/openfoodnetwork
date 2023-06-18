# frozen_string_literal: false

class Invoice
  class DataPresenter
    class ShippingMethod < Invoice::DataPresenter::Base
      attributes :id, :name, :require_ship_address
      invoice_generation_attributes :id
    end
  end
end
