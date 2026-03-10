# frozen_string_literal: false

class Invoice
  class DataPresenter
    class PaymentMethod < Invoice::DataPresenter::Base
      attributes :id, :display_name, :display_description
      invoice_generation_attributes :id
    end
  end
end
