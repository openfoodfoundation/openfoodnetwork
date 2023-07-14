# frozen_string_literal: false

class Invoice
  class DataPresenter
    class TaxRate < Invoice::DataPresenter::Base
      attributes :id, :amount
    end
  end
end
