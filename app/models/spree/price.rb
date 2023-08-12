# frozen_string_literal: false

module Spree
  class Price < ApplicationRecord
    self.belongs_to_required_by_default = false

    acts_as_paranoid without_default_scope: true

    belongs_to :variant, -> { with_deleted }, class_name: 'Spree::Variant'

    validate :check_price
    validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

    def display_amount
      money
    end
    alias :display_price :display_amount

    def money
      Spree::Money.new(amount || 0, currency: currency)
    end

    def price
      amount
    end

    def price=(price)
      self[:amount] = parse_price(price)
    end

    private

    def check_price
      return unless currency.nil?

      self.currency = Spree::Config[:currency]
    end

    # strips all non-price-like characters from the price, taking into account locale settings
    def parse_price(price)
      return price unless price.is_a?(String)

      separator, _delimiter = I18n.t([:'number.currency.format.separator',
                                      :'number.currency.format.delimiter'])
      non_price_characters = /[^0-9\-#{separator}]/
      # Strip everything else first
      price.gsub!(non_price_characters, '')
      # Then replace the locale-specific decimal separator with the standard separator if necessary
      price.gsub!(separator, '.') unless separator == '.'

      price.to_d
    end
  end
end
