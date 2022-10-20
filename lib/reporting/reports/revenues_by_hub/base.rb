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

        def columns # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
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
            total_excl_tax: proc { |orders|
                              orders.sum { |order| order.total - order.total_tax }
                            },
            total_tax: proc { |orders| orders.sum(&:total_tax) },
            total_incl_tax: proc { |orders| orders.sum(&:total) }
          }
        end

        def query_result
          search.result.group_by(&:distributor).values
        end

        private

        def distributor(orders)
          orders.first.distributor
        end
      end
    end
  end
end
