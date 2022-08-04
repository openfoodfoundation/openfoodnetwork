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

        def columns
          {
            hub: proc { |orders| distributor(orders).name },
            hub_id: proc { |orders| distributor(orders).id },
            hub_owner_email: proc { |orders| distributor(orders).owner.email },
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
