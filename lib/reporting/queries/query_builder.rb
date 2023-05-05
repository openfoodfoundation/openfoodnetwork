# frozen_string_literal: true

module Reporting
  module Queries
    class QueryBuilder < QueryInterface
      include Joins
      include Tables

      attr_reader :grouping_fields

      def initialize(model, grouping_fields = proc { [] })
        @grouping_fields = instance_exec(&grouping_fields)

        super model.arel_table
      end

      def selecting(lambda)
        fields = instance_exec(&lambda).map{ |key, value| value.public_send(:as, key.to_s) }

        reflect query.project(*fields)
      end

      def scoped_to_orders(orders_relation)
        reflect query.where(
          line_item_table[:order_id].in(Arel.sql(orders_relation.to_sql))
        )
      end

      def scoped_to_line_items(line_items_relation)
        reflect query.where(
          line_item_table[:id].in(Arel.sql(line_items_relation.to_sql))
        )
      end

      def with_managed_orders(orders_relation)
        reflect query.
          outer_join(managed_orders_alias).
          on(
            managed_orders_alias[:id].eq(line_item_table[:order_id]).
            and(managed_orders_alias[:distributor_id].in(Arel.sql(orders_relation.to_sql)))
          )
      end

      def grouped_in_sets(group_sets)
        reflect query.group(*instance_exec(&group_sets))
      end

      def ordered_by(ordering_fields)
        reflect query.order(*instance_exec(&ordering_fields))
      end

      def masked(field, message = nil, mask_rule = nil)
        Case.new.
          when(mask_rule || default_mask_rule).
          then(field).
          else(quoted(message || I18n.t("hidden_field", scope: i18n_scope)))
      end

      def distinct_results(fields = nil)
        return reflect query.distinct if fields.blank?

        reflect query.distinct_on(fields)
      end

      private

      def default_mask_rule
        line_item_table[:order_id].in(raw("#{managed_orders_alias.name}.id")).
          or(distributor_alias[:show_customer_names_to_suppliers].eq(true))
      end

      def summary_row_title
        I18n.t("total", scope: i18n_scope)
      end

      def i18n_scope
        "admin.reports"
      end
    end
  end
end
