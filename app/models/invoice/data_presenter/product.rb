# frozen_string_literal: false

class Invoice
  class DataPresenter
    class Product < Invoice::DataPresenter::Base
      attributes :name
      attributes_with_presenter :supplier
    end
  end
end
