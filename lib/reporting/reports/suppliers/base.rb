# frozen_string_literal: true

module Reporting
  module Reports
    module Suppliers
      class Base < ReportTemplate
        include Helpers::ColumnsHelper

        def default_params
          {
            q: {
              completed_at_gt: 1.month.ago.beginning_of_day,
              completed_at_lt: 1.day.from_now.beginning_of_day
            }
          }
        end

        def search
          report_line_items.orders
        end

        def query_result
          report_line_items.list(line_item_includes)
        end

        def columns
          {
            producer:,
            producer_address:,
            producer_abn_acn:,
            email:,
            hub:,
            hub_address:,
            hub_contact_email:,
            order_number:,
            order_date:,
            order_cycle:,
            order_cycle_start_date:,
            order_cycle_end_date:,
            product:,
            variant_unit_name:,
            quantity:,
            total_excl_fees_and_tax:,
            total_excl_vat:,
            total_fees_excl_tax:,
            total_tax_on_fees:,
            total_tax:,
            total:,
          }
        end

        def rules
          [
            {
              group_by: :producer,
              header: true,
              summary_row: proc do |_key, line_items|
                summary_hash = Hash.new(0)

                line_items.each do |line_item|
                  summary_hash[:total_excl_fees_and_tax] += total_excl_fees_and_tax.call(line_item)
                  summary_hash[:total_excl_vat] += total_excl_vat.call(line_item)
                  summary_hash[:total_fees_excl_tax] += total_fees_excl_tax.call(line_item)
                  summary_hash[:total_tax_on_fees] += total_tax_on_fees.call(line_item)
                  summary_hash[:total_tax] += total_tax.call(line_item)
                  summary_hash[:total] += total.call(line_item)
                end

                summary_hash
              end
            }
          ]
        end

        private

        def order_permissions
          return @order_permissions unless @order_permissions.nil?

          @order_permissions = ::Permissions::Order.new(@user, ransack_params)
        end

        def report_line_items
          @report_line_items ||= Reporting::LineItems.new(order_permissions, params)
        end

        def line_item_includes
          [{
            order: [
              :distributor,
              :adjustments,
            ],
            variant: [:product, :supplier]
          }]
        end
      end
    end
  end
end
