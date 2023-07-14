# frozen_string_literal: false

class Invoice
  class DataPresenter
    class AdjustmentOriginator < Invoice::DataPresenter::Base
      attributes :id, :type, :amount
    end
  end
end
