# frozen_string_literal: false

class Invoice
  class DataPresenter
    class Product < Invoice::DataPresenter::Base
      attributes :name
    end
  end
end
