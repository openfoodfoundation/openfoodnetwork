# frozen_string_literal: true

module Spree
  module Core
    class FakeMethod
      # testing Undercover!
      # it's a random method, with no test coverage
      def square(number)
        number * number
      end
    end
  end
end
