# frozen_string_literal: false

class Invoice
  class DataPresenter
    class Base
      attr :data

      def initialize(data)
        @data = data
      end
      extend Invoice::DataPresenterAttributes
    end
  end
end
