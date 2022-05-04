# frozen_string_literal: true

module Reporting
  module Reports
    module SalesTax
      class Base < ReportTemplate
        def search
          permissions = ::Permissions::Order.new(user)
          permissions.editable_orders.complete.not_state(:canceled).ransack(ransack_params)
        end

        def query_result
          search.result
        end

        private

        def relevant_rates
          @relevant_rates ||= Spree::TaxRate.distinct
        end

        def order_number_column(order)
          if html_render?
            url = Spree::Core::Engine.routes.url_helpers.edit_admin_order_path(order.number)
            <<-HTML
              <a href=#{url} class="edit-order" target="_blank">#{order.number}</a>
            HTML
          else
            order.number
          end
        end
      end
    end
  end
end
