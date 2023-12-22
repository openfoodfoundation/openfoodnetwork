# frozen_string_literal: true

module Reporting
  module Reports
    module RevenuesByHub
      class Base < ReportTemplate
        def search
          permissions = ::Permissions::Order.new(user)
          sold_states = %w(complete resumed)
          permissions.editable_orders.where(state: sold_states).ransack(ransack_params)
        end

        def default_params
          {
            q: {
              completed_at_gt: 1.month.ago.beginning_of_day,
              completed_at_lt: 1.day.from_now.beginning_of_day
            }
          }
        end

        def columns # rubocop:disable Metrics/AbcSize
          {
            hub: proc { |orders| distributor(orders).name },
            hub_id: proc { |orders| distributor(orders).id },
            hub_business_number: proc { |orders| distributor(orders).abn },
            hub_legal_name: proc { |orders| distributor(orders).business_address&.company },
            hub_contact_name: proc { |orders| distributor(orders).contact_name },
            hub_email: proc { |orders| distributor(orders).email_address },
            hub_owner_email: proc { |orders| distributor(orders).owner.email },
            hub_phone: proc { |orders| distributor(orders).phone },
            hub_address_line1: proc { |orders| distributor(orders).address&.address1 },
            hub_address_line2: proc { |orders| distributor(orders).address&.address2 },
            hub_address_city: proc { |orders| distributor(orders).address&.city },
            hub_address_zipcode: proc { |orders| distributor(orders).address&.zipcode },
            hub_address_state_name: proc { |orders| distributor(orders).address&.state_name },
            total_orders: proc { |orders| orders.count },
            total_excl_tax: :total_excl_tax,
            total_tax: :total_tax,
            total_incl_tax: :total_incl_tax
          }
        end

        def query_result
          result = search.result.group_by(&:distributor).values
          build_tax_data(result)
          result
        end

        private

        def distributor(orders)
          orders.first.distributor
        end

        def build_tax_data(grouped_orders)
          @tax_data = {}

          grouped_orders.each do |orders|
            voucher_adjustments = calculate_voucher_adjustments(orders)

            total_incl_tax = orders.sum(&:total)
            total_tax = orders.sum(&:total_tax) + voucher_adjustments
            total_excl_tax = total_incl_tax - total_tax

            @tax_data[distributor(orders).id] = {
              total_incl_tax:, total_tax:, total_excl_tax:
            }
          end
        end

        def calculate_voucher_adjustments(orders)
          result = 0.0

          orders.each do |order|
            adjustment_service = VoucherAdjustmentsService.new(order)
            result += adjustment_service.voucher_included_tax +
                      adjustment_service.voucher_excluded_tax
          end

          result
        end

        def total_incl_tax(orders)
          @tax_data[distributor(orders).id][:total_incl_tax]
        end

        def total_tax(orders)
          @tax_data[distributor(orders).id][:total_tax]
        end

        def total_excl_tax(orders)
          @tax_data[distributor(orders).id][:total_excl_tax]
        end
      end
    end
  end
end
