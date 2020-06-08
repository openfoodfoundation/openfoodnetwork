# frozen_string_literal: true

module Reports
  module Packing
    class Base < ReportTemplate
      SUBTYPES = ["customer", "supplier"]

      def collection
        Spree::LineItem.includes(*line_item_includes).references(:line_items).
          where(order_id: order_ids).uniq
      end

      def summary_row
        { title: I18n.t("summary_row.total", scope: i18n_scope), sum: [:quantity] }
      end

      def mask_data_rules
        [{
          columns: [:customer_code, :first_name, :last_name],
          replacement: I18n.t("hidden_field", scope: i18n_scope),
          rule: proc{ |line_item| !can_view_customer_data?(line_item) }
        }]
      end

      private

      def permissions
        ::Permissions::Order.new(current_user, ransack_params)
      end

      def orders
        @orders ||= permissions.visible_orders.
          complete.not_state(:canceled).
          includes(:bill_address, :distributor, :customer).references(:orders).
          ransack(ransack_params).result.index_by(&:id)
      end

      def order_ids
        orders.keys
      end

      def line_item_includes
        [{
          option_values: :option_type,
          variant: { product: [:supplier, :shipping_category] }
        }]
      end

      def can_view_customer_data?(line_item)
        managed_enterprise_ids.include? orders[line_item.order_id].distributor_id
      end

      def managed_enterprise_ids
        @managed_enterprise_ids ||= Enterprise.managed_by(current_user).pluck(:id)
      end

      def temp_controlled_value(object)
        object.product.shipping_category&.temperature_controlled ? I18n.t(:yes) : I18n.t(:no)
      end

      def i18n_scope
        "admin.reports"
      end
    end
  end
end
