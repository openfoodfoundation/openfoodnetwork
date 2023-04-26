# frozen_string_literal: false

class Invoice
  class DataPresenter
    class OrderCycle < Invoice::DataPresenter::Base
      attributes :name
    end
  end
end
