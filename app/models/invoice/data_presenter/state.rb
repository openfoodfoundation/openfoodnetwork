# frozen_string_literal: false

class Invoice
  class DataPresenter
    class State < Invoice::DataPresenter::Base
      attributes :name
    end
  end
end
