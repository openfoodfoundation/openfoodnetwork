# frozen_string_literal: true

module Reporting
  module Reports
    module SalesTax
      class TaxRates < Base
        # rubocop:disable Rails/OutputSafety
        def columns
          result = {
            order_number: proc { |order| order_number_column(order).html_safe },
            total_excl_vat: proc { |order| order.total - order.total_tax }
          }
          add_key_for_each_rate(result, proc { |rate|
            proc { |order| OrderTaxAdjustmentsFetcher.new(order).totals.fetch(rate, 0) }
          })
          other = {
            total_tax: proc { |order| order.total_tax },
            total_incl_vat: proc { |order| order.total }
          }
          result.merge(other)
        end
        # rubocop:enable Rails/OutputSafety

        def custom_headers
          result = {}
          add_key_for_each_rate(result, proc { |rate|
            "%.1f%% (%s)" % [rate.amount.to_f * 100, currency_symbol]
          })
          result
        end

        private

        def add_key_for_each_rate(result, proc)
          relevant_rates.each { |rate|
            result["rate_#{rate.id}"] = proc.call(rate)
          }
        end
      end
    end
  end
end
