# frozen_string_literal: true

module Reporting
  module Reports
    module Payments
      class Base < ReportTemplate
        def search
          Spree::Order.complete.not_state(:canceled).managed_by(@user).ransack(ransack_params)
        end

        def query_result
          search.result.group_by { |order| [order.payment_state, order.distributor] }.values
        end

        protected

        def payment_state(order)
          I18n.t "spree.payment_states.#{order.payment_state}"
        end
      end
    end
  end
end
