# frozen_string_literal: false

class Invoice
  class DataPresenter
    class Contact < Invoice::DataPresenter::Base
      attributes :name, :email
    end
  end
end
