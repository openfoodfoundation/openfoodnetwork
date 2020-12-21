# frozen_string_literal: true

module Spree
  module MoneyHelper
    def with_currency(amount, options = {})
      Spree::Money.new(amount, options).to_s
    end
  end
end
