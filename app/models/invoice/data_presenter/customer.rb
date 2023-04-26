# frozen_string_literal: false

class Invoice
  class DataPresenter
    class Customer < Invoice::DataPresenter::Base
      attributes :code, :email
    end
  end
end
