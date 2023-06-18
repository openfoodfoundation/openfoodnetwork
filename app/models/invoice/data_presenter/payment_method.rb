# frozen_string_literal: false

class Invoice
  class DataPresenter
    class PaymentMethod < Invoice::DataPresenter::Base
      attributes :id, :name, :description
      invoice_generation_attributes :id
    end
  end
end
