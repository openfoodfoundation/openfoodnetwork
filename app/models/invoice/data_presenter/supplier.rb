# frozen_string_literal: false

class Invoice
  class DataPresenter
    class Supplier < Invoice::DataPresenter::Base
      attributes :name
    end
  end
end
