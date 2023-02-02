# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Reporting
  module Reports
    module EnterpriseFeeSummary
      class EnterpriseFeesWithTaxReportByProducer < ReportTemplate
        attr_accessor :permissions

        def initialize(user, params = {}, render: false)
          super(user, params, render: render)
          @permissions = Permissions.new(user)
        end

        def search
          report_line_items.orders
        end

        def order_permissions
          @order_permissions ||= ::Permissions::Order.new(user, ransack_params)
        end

        def report_line_items
          @report_line_items ||= Reporting::LineItems.new(order_permissions, params)
        end

        def supplier_ids_filter(supplier_id)
          return true if params[:supplier_id_in].blank?

          params[:supplier_id_in].include?(supplier_id)
        end

        def enterprise_fee_filtered_ids
          return @enterprise_fee_filtered_ids unless @enterprise_fee_filtered_ids.nil?

          @enterprise_fee_filtered_ids = EnterpriseFee.where(nil)
          unless enterprise_fee_ids_filter.empty?
            @enterprise_fee_filtered_ids = @enterprise_fee_filtered_ids.where(
              id: enterprise_fee_ids_filter
            )
          end
          unless enterprise_fee_owner_ids_filter.empty?
            @enterprise_fee_filtered_ids = @enterprise_fee_filtered_ids.where(
              enterprise_id: enterprise_fee_owner_ids_filter
            )
          end
          @enterprise_fee_filtered_ids = @enterprise_fee_filtered_ids.pluck(:id)
        end

        def enterprise_fee_filters?
          enterprise_fee_ids_filter + enterprise_fee_owner_ids_filter != []
        end

        def enterprise_fee_ids_filter
          ransack_params["enterprise_fee_id_in"]&.filter(&:present?) || []
        end

        def enterprise_fee_owner_ids_filter
          ransack_params["enterprise_fee_owner_id_in"]&.filter(&:present?) || []
        end

        def query_result
          # The objective is to group the orders by
          # [entreprise_fee, tax_rate, supplier_id, distributor_id and order_cycle_id]

          # The order.all_adjustment describes
          #   - the enterprise fees applied on the order
          #   - the enterprise fees applied on the line items
          #   - all the taxes including, the taxes applied on the enterprise fees
          # The access to enterprise fee tax rates is done in two steps
          #   1.we'll need to store two attributes for each order.all_adjustemnt.enterprise_fee
          #     a. originator_id will refer to the enterprise fee instance
          #     b. id of the adjustment
          #   2. order.all_adjustemnt.tax.where(adjustment_id: id,"Spree::Adjustment")
          #     - this will return the tax applied on the enterprise fees
          orders = report_line_items.list.map(&:order).uniq
          orders.flat_map(&join_enterprise_fee)
            .flat_map(&join_tax_rate)
            .flat_map(&join_supplier)
            .group_by(&group_keys)
            .each(&change_root_to_order)
        end

        def join_enterprise_fee
          proc do |order|
            query = order
              .all_adjustments
              .enterprise_fee

            if enterprise_fee_filters?
              query = query.where(originator_id: enterprise_fee_filtered_ids)
            end
            query.group('originator_id')
              .pluck("originator_id", 'array_agg(id)')
              .map do |enterprise_fee_id, enterprise_fee_adjustment_ids|
                {
                  enterprise_fee_id: enterprise_fee_id,
                  enterprise_fee_adjustment_ids: enterprise_fee_adjustment_ids,
                  order: order
                }
              end
          end
        end

        def join_tax_rate
          proc do |item|
            tax_rate_ids = item[:order].all_adjustments.tax.where(
              adjustable_id: item[:enterprise_fee_adjustment_ids],
              adjustable_type: "Spree::Adjustment"
            ).pluck(:originator_id)

            tax_rate_ids << nil if tax_rate_ids.empty?
            tax_rate_ids.map do |tax_rate_id|
              {
                tax_rate_id: tax_rate_id,
                enterprise_fee_id: item[:enterprise_fee_id],
                order: item[:order],
              }
            end
          end
        end

        def join_supplier
          proc do |item|
            order = item[:order]
            order
              .line_items
              .map(&:supplier_id)
              .filter(&method(:supplier_ids_filter))
              .map do |supplier_id|
                {
                  tax_rate_id: item[:tax_rate_id],
                  enterprise_fee_id: item[:enterprise_fee_id],
                  supplier_id: supplier_id,
                  order: order
                }
              end
          end
        end

        def group_keys
          proc do |hash|
            [
              hash[:tax_rate_id],
              hash[:enterprise_fee_id],
              hash[:supplier_id],
              hash[:order].distributor_id,
              hash[:order].order_cycle_id
            ]
          end
        end

        def change_root_to_order
          proc do |_, v|
            v.map!{ |item| item[:order] }
          end
        end

        def columns
          {
            distributor: :distributor,
            producer: :producer,
            producer_tax_status: :producer_tax_status,
            order_cycle: :order_cycle,
            enterprise_fee_name: :enterprise_fee_name,
            enterprise_fee_type: :enterprise_fee_type,
            enterprise_fee_owner: :enterprise_fee_owner,
            tax_category: :tax_category,
            tax_rate_name: :tax_rate_name,
            tax_rate: :tax_rate_amount,
            total_excl_tax: :total_excl_tax,
            tax: :tax,
            total_incl_tax: :total_incl_tax
          }
        end

        def rules
          [
            { group_by: :distributor },
            { group_by: :producer },
            { group_by: :order_cycle, summary_row: order_cycle_totals_row }
          ]
        end

        def order_cycle_totals_row
          proc do |_key, items, _rows|
            order_ids = items.flat_map(&:second).map(&:id).uniq

            total_excl_tax = total_fees_excl_tax(order_ids)
            tax = tax_for_order_ids(order_ids)
            {
              total_excl_tax: total_excl_tax,
              tax: tax,
              total_incl_tax: total_excl_tax + tax
            }
          end
        end

        def total_fees_excl_tax(order_ids)
          enterprise_fees_amount_for_orders(order_ids) - included_tax_for_order_ids(order_ids)
        end

        def included_tax_for_order_ids(order_ids)
          Spree::Adjustment.tax
            .where(order: order_ids)
            .where(included: true)
            .where(adjustable_type: 'Spree::Adjustment')
            .where(adjustable_id: enterprise_fee_adjustment_ids_for_orders(order_ids))
            .pluck("sum(amount)")
            .first || 0
        end

        def tax_for_order_ids(order_ids)
          Spree::Adjustment.tax
            .where(order: order_ids)
            .where(adjustable_type: 'Spree::Adjustment')
            .where(adjustable_id: enterprise_fee_adjustment_ids_for_orders(order_ids))
            .pluck("sum(amount)")
            .first || 0
        end

        def enterprise_fee_adjustment_ids_for_orders(order_ids)
          enterprise_fees_for_orders(order_ids).pluck(:id)
        end

        def enterprise_fees_amount_for_orders(order_ids)
          enterprise_fees_for_orders(order_ids).pluck("sum(amount)").first || 0
        end

        def enterprise_fees_for_orders(order_ids)
          enterprise_fees = Spree::Adjustment.enterprise_fee
            .where(order_id: order_ids)
          return enterprise_fees unless enterprise_fee_filters?

          enterprise_fees.where(
            originator_id: enterprise_fee_filtered_ids
          )
        end

        def distributor(query_result_row)
          first_order(query_result_row).distributor&.name
        end

        def producer(query_result_row)
          Enterprise.where(id: supplier_id(query_result_row)).pick(:name)
        end

        def producer_tax_status(query_result_row)
          Enterprise.where(id: supplier_id(query_result_row)).pluck(:charges_sales_tax).first
        end

        def order_cycle(query_result_row)
          first_order(query_result_row).order_cycle&.name
        end

        def enterprise_fee_name(query_result_row)
          enterprise_fee(query_result_row).name
        end

        def enterprise_fee_type(query_result_row)
          enterprise_fee(query_result_row).fee_type
        end

        def enterprise_fee_owner(query_result_row)
          enterprise_fee(query_result_row).enterprise.name
        end

        def tax_category(query_result_row)
          tax_rate(query_result_row)&.tax_category&.name
        end

        def tax_rate_name(query_result_row)
          tax_rate(query_result_row)&.name
        end

        def tax_rate_amount(query_result_row)
          tax_rate(query_result_row)&.amount
        end

        def total_excl_tax(query_result_row)
          order_ids = orders(query_result_row).map(&:id)
          enterprise_fee_id = enterprise_fee_id(query_result_row)
          amount = Spree::Adjustment.enterprise_fee
            .where(order_id: order_ids)
            .where(originator_id: enterprise_fee_id)
            .pluck("sum(amount)")
            .first
          amount - tax(query_result_row, all: true, included: true)
        end

        def tax(query_result_row, all: false, included: nil)
          order_ids = orders(query_result_row).map(&:id)
          adjustment_ids = enterprise_fee_adjustemnt_ids(query_result_row)
          query = Spree::Adjustment.tax
          query = query.where(included: true) unless included.nil?
          query = query.where(originator_id: tax_rate_id(query_result_row)) unless all == true
          query = query.where(order_id: order_ids)
            .where(adjustable_type: 'Spree::Adjustment')
            .where(adjustable_id: adjustment_ids)
            .pluck("sum(amount)")

          query.first || 0
        end

        def total_incl_tax(query_result_row)
          total_excl_tax(query_result_row) + tax(query_result_row, all: false)
        end

        def enterprise_fee_adjustemnt_ids(query_result_row)
          order_ids = orders(query_result_row).map(&:id)
          enterprise_fee_id = enterprise_fee_id(query_result_row)
          Spree::Adjustment.enterprise_fee
            .where(order_id: order_ids)
            .where(originator_id: enterprise_fee_id)
            .pluck(:id)
        end

        def enterprise_fee(query_result_row)
          first_order(query_result_row).all_adjustments
            .enterprise_fee
            .find_by(originator_id: enterprise_fee_id(query_result_row))
            .originator
        end

        def tax_rate(query_result_row)
          return nil if tax_rate_id(query_result_row).nil?

          Spree::TaxRate.find(tax_rate_id(query_result_row))
        end

        def first_order(query_result_row)
          orders(query_result_row).first
        end

        def tax_rate_id(query_result_row)
          keys(query_result_row)[0]
        end

        def supplier_id(query_result_row)
          keys(query_result_row)[2]
        end

        def enterprise_fee_id(query_result_row)
          keys(query_result_row)[1]
        end

        def keys(query_result_row)
          query_result_row.first
        end

        def orders(query_result_row)
          query_result_row.second
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
