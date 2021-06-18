# frozen_string_literal: true

module Spree
  module Admin
    module GeneralSettingsHelper
      def currency_options
        currencies = ::Money::Currency.table.map do |_code, details|
          iso = details[:iso_code]
          [iso, "#{details[:name]} (#{iso})"]
        end
        options_from_collection_for_select(currencies, :first, :last, Spree::Config[:currency])
      end

      def all_units
        ["g", "oz", "lb", "kg", "T", "mL", "L", "kL"]
      end
    end
  end
end
