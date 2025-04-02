# frozen_string_literal: true

# Mask user data from suppliers, unless explicitly allowed
# See also: app/services/orders/mask_data_service.rb
#
module Reporting
  module Queries
    module MaskData
      include Tables

      def mask_customer_name(field)
        masked(field, managed_order_mask_rule(:show_customer_names_to_suppliers))
      end

      def mask_contact_data(field)
        masked(field, managed_order_mask_rule(:show_customer_contacts_to_suppliers))
      end

      def masked(field, mask_rule = nil)
        Arel::Nodes::Case.new.
          when(mask_rule).
          then(field).
          else(quoted(I18n.t("hidden_field", scope: i18n_scope)))
      end

      private

      # Show unmasked data if order is managed by user, or if distributor allows suppliers
      def managed_order_mask_rule(condition_name)
        id = raw("#{managed_orders_alias.name}.id") # rubocop:disable Rails/OutputSafety
        line_item_table[:order_id].in(id).
          or(distributor_alias[condition_name].eq(true))
      end
    end
  end
end
