# frozen_string_literal: true

module Reporting
  module Reports
    module EnterpriseFeeSummary
      class EnterpriseFeesWithTaxReportByOrder < ReportTemplate
        attr_accessor :parameters

        def initialize(user, params = {}, render: false)
          super(user, params, render: render)
        end

        def search
          report_line_items.orders
        end

        def order_permissions
          return @order_permissions unless @order_permissions.nil?

          @order_permissions = ::Permissions::Order.new(user, ransack_params)
        end

        def report_line_items
          @report_line_items ||= Reporting::LineItems.new(order_permissions, params)
        end

        def query_result
          # The objective is to group the orders by
          # [enterpirse fees,tax_rate, order]
          orders = search.result.to_a
          orders.flat_map(&join_enterprise_fee)
            .flat_map(&join_tax_rate)
            .group_by(&group_keys)
            .map(&change_root_to_order)
        end

        def join_enterprise_fee
          proc do |order|
            order
              .all_adjustments
              .enterprise_fee
              .group('originator_id')
              .pluck("originator_id", 'array_agg(id)')
              .filter(&method(:filter_enterprise_fee_by_id))
              .filter(&method(:filter_enterprise_fee_by_owner))
              .map do |enterprise_fee_id, enterprise_fee_adjustment_ids|
              {
                enterprise_fee_id: enterprise_fee_id,
                enterprise_fee_adjustment_ids: enterprise_fee_adjustment_ids,
                order: order
              }
            end
          end
        end

        # [enteperise_fee_id, [adjustment_ids]]
        def filter_enterprise_fee_by_id(arg)
          return true unless filter_enterprise_fee_by_id_active?

          enterprise_fee_id = arg.first.to_s
          enterprise_fee_id.in?(ransack_params[:enterprise_fee_id_in])
        end

        def filter_enterprise_fee_by_owner(arg)
          return true unless filter_enteprise_fee_by_owner_active?

          enterprise_fee_id = arg.first

          EnterpriseFee.exists?(id: enterprise_fee_id,
                                enterprise_id: ransack_params[:enterprise_fee_owner_id_in] )
        end

        def filter_enterprise_fee_by_id_active?
          !ransack_params[:enterprise_fee_id_in].compact_blank.empty?
        end

        def filter_enteprise_fee_by_owner_active?
          !ransack_params[:enterprise_fee_owner_id_in].compact_blank.empty?
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

        def group_keys
          proc do |hash|
            [
              hash[:tax_rate_id],
              hash[:enterprise_fee_id],
              hash[:order].id
            ]
          end
        end

        def change_root_to_order
          proc do |k, v|
            [k, v.first[:order]]
          end
        end

        def columns
          {
            distributor: :distributor,
            order_cycle: :order_cycle,
            order_number: :order_number,
            enterprise_fee_name: :enterprise_fee_name,
            enterprise_fee_type: :enterprise_fee_type,
            enterprise_fee_owner: :enterprise_fee_owner,
            tax_category: :tax_category,
            tax_rate_name: :tax_rate_name,
            tax_rate: :tax_rate_amount,
            total_excl_tax: :total_excl_tax,
            tax: :tax,
            total_incl_tax: :total_incl_tax,
            customer_first_name: :customer_first_name,
            customer_last_name: :customer_last_name,
            customer_code: :customer_code,
            customer_email: :customer_email
          }
        end

        def rules
          [
            { group_by: :distributor },
            { group_by: :order_cycle },
            {
              group_by: :order_number,
              summary_row: proc do |_key, items, _rows|
                item = items.first
                order = item.second
                enterprise_fees = enterprise_fees_sum(order)
                {
                  total_excl_tax: enterprise_fees - enterprise_fee_tax(order, included: true),
                  tax: enterprise_fee_tax(order),
                  total_incl_tax: enterprise_fees + enterprise_fee_tax(order, added: true),
                  customer_first_name: order.customer&.first_name,
                  customer_last_name: order.customer&.last_name,
                  customer_code: order.customer&.code,
                  customer_email: order.customer&.email
                }
              end
            }
          ]
        end

        def enterprise_fees_sum(order)
          enterprise_fees(order).sum(:amount)
        end

        def enterprise_fees(order)
          query = order.all_adjustments.enterprise_fee
          if filter_enterprise_fee_by_id_active?
            query = query.where(originator_id: ransack_params[:enterprise_fee_id_in])
          end
          if filter_enteprise_fee_by_owner_active?
            query = query.where(originator_id: enterprise_fee_ids_for_selected_owners)
          end
          query
        end

        def enterprise_fee_ids_for_selected_owners
          EnterpriseFee.where( enterprise_id: ransack_params[:enterprise_fee_owner_id_in] )
            .pluck(:id)
        end

        def enterprise_fee_tax(order, included: false, added: false)
          query = order.all_adjustments.tax
          query = query.inclusive if included == true
          query = query.additional if added == true
          query.where(adjustable: enterprise_fees(order)).sum(:amount)
        end

        def distributor(query_result_row)
          order(query_result_row).distributor&.name
        end

        def order_cycle(query_result_row)
          order(query_result_row).order_cycle&.name
        end

        def order_number(query_result_row)
          order(query_result_row).number
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
          amount = Spree::Adjustment.enterprise_fee
            .where(order: order(query_result_row))
            .where(originator_id: enterprise_fee_id(query_result_row))
            .pick("sum(amount)") || 0
          amount - tax(query_result_row, all: true, included: true)
        end

        def tax(query_result_row, all: false, included: nil)
          order_id = order(query_result_row).id
          adjustment_ids = enterprise_fee_adjustment_ids(query_result_row)
          query = Spree::Adjustment.tax
          query = query.where(included: true) unless included.nil?
          query = query.where(originator_id: tax_rate_id(query_result_row)) unless all == true
          query.where(order_id: order_id)
            .where(adjustable_type: 'Spree::Adjustment')
            .where(adjustable_id: adjustment_ids)
            .pick("sum(amount)") || 0
        end

        def total_incl_tax(query_result_row)
          total_excl_tax(query_result_row) + tax(query_result_row, all: false)
        end

        def customer_first_name(query_result_row)
          order(query_result_row).customer&.first_name
        end

        def customer_last_name(query_result_row)
          order(query_result_row).customer&.last_name
        end

        def customer_code(query_result_row)
          order(query_result_row).customer&.code
        end

        def customer_email(query_result_row)
          order(query_result_row).customer&.email
        end

        def enterprise_fee_adjustment_ids(query_result_row)
          Spree::Adjustment.enterprise_fee
            .where(order: order(query_result_row))
            .where(originator_id: enterprise_fee_id(query_result_row))
            .pluck(:id)
        end

        def enterprise_fee(query_result_row)
          order(query_result_row).all_adjustments
            .enterprise_fee
            .find_by(originator_id: enterprise_fee_id(query_result_row))
            .originator
        end

        def tax_rate(query_result_row)
          return nil if tax_rate_id(query_result_row).nil?

          Spree::TaxRate.find(tax_rate_id(query_result_row))
        end

        def order(query_result_row)
          query_result_row.second
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
      end
    end
  end
end
