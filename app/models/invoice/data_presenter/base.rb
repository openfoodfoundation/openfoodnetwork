# frozen_string_literal: false

class Invoice
  class DataPresenter
    class Base
      attr_reader :data

      def initialize(data)
        @data = data
      end
      extend Invoice::DataPresenterAttributes
    end
  end
end
